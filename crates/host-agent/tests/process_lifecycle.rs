// SPDX-License-Identifier: MPL-2.0

#![cfg(unix)]

use std::{fs, path::Path, sync::Arc};

use prost::Message;
use roammand_host_agent::{AgentRuntime, AgentRuntimeConfig, RuntimeError};
use roammand_host_platform::{MemorySecretStore, RuntimePaths};
use roammand_ipc::{IpcToken, client_proof, encode_frame, server_proof};
use roammand_protocol::{
    identity_derivation::derive_device_id_v1,
    roammand::v1::{
        CreateControllerGrantRequest, DeviceIdentity, DevicePlatform, GetHostPairingStatusRequest,
        GetHostStatusRequest, HostPairingState, HostPairingStatusSnapshot,
        ListControllerGrantsRequest, LocalIpcAuthenticate, LocalIpcClientFrame,
        LocalIpcServerFrame, ProtocolVersion, PublicKeyAlgorithm, SessionPermission,
        local_ipc_client_frame, local_ipc_server_frame,
    },
};
use tempfile::TempDir;
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    net::UnixStream,
    time::{Duration, timeout},
};

#[cfg(feature = "native-webrtc")]
use roammand_host_agent::RemoteRuntimeConfig;
#[cfg(feature = "native-webrtc")]
use roammand_host_webrtc::IceTransportPolicy;
#[cfg(feature = "native-webrtc")]
use tokio::{net::TcpListener, sync::oneshot};
#[cfg(feature = "native-webrtc")]
use tokio_tungstenite::{
    accept_hdr_async,
    tungstenite::{
        handshake::server::{ErrorResponse, Request, Response},
        http::{HeaderValue, header::SEC_WEBSOCKET_PROTOCOL},
    },
};

const CLIENT_NONCE: [u8; 32] = [0x31; 32];
const IO_TIMEOUT: Duration = Duration::from_secs(2);

#[tokio::test]
async fn reconnect_and_restart_preserve_identity_and_grants_then_cleanup() {
    let fixture = Fixture::new();
    let first = AgentRuntime::start_with_store(&fixture.config(), fixture.secret_store.as_ref())
        .expect("first Agent must start");

    let mut client = TestClient::connect(fixture.runtime_dir()).await;
    let first_identity = client.host_identity().await;
    let first_pairing = client.pairing_status().await;
    assert_eq!(first_pairing.state, HostPairingState::Idle as i32);
    drop(client);
    let mut reconnected = TestClient::connect(fixture.runtime_dir()).await;
    assert_eq!(reconnected.host_identity().await, first_identity);
    assert_eq!(reconnected.pairing_status().await, first_pairing);
    reconnected.create_grant(controller()).await;
    assert_eq!(reconnected.grant_count().await, 1);
    drop(reconnected);

    first.shutdown().await.expect("first Agent must stop");
    assert_runtime_artifacts_absent(fixture.runtime_dir());

    let restarted =
        AgentRuntime::start_with_store(&fixture.config(), fixture.secret_store.as_ref())
            .expect("Agent must restart");
    let mut after_restart = TestClient::connect(fixture.runtime_dir()).await;
    assert_eq!(after_restart.host_identity().await, first_identity);
    assert_eq!(after_restart.grant_count().await, 1);
    drop(after_restart);
    restarted
        .shutdown()
        .await
        .expect("restarted Agent must stop");
    assert_runtime_artifacts_absent(fixture.runtime_dir());
}

#[tokio::test]
async fn rejects_a_second_instance_without_exposing_runtime_secrets() {
    let fixture = Fixture::new();
    let first = AgentRuntime::start_with_store(&fixture.config(), fixture.secret_store.as_ref())
        .expect("first Agent must start");

    let error = AgentRuntime::start_with_store(&fixture.config(), fixture.secret_store.as_ref())
        .expect_err("second Agent must be rejected");
    assert_eq!(error, RuntimeError::AlreadyRunning);
    let public_error = format!("{error:?} {error}");
    assert!(!public_error.contains(&fixture.runtime_dir().display().to_string()));
    let token = fs::read(fixture.runtime_dir().join("ipc-token.bin"))
        .expect("first Agent token must exist");
    assert!(
        !public_error
            .as_bytes()
            .windows(token.len())
            .any(|part| part == token)
    );

    first.shutdown().await.expect("first Agent must stop");
    assert_runtime_artifacts_absent(fixture.runtime_dir());
}

#[cfg(feature = "native-webrtc")]
#[tokio::test]
async fn shutdown_cancels_an_unresponsive_signaling_registration() {
    let fixture = Fixture::new();
    let signaling = TcpListener::bind("127.0.0.1:0")
        .await
        .expect("fake signaling listener must bind");
    let endpoint = format!(
        "ws://{}/session",
        signaling.local_addr().expect("listener address")
    );
    let (accepted_sender, accepted_receiver) = oneshot::channel();
    let server = tokio::spawn(async move {
        let (stream, _) = signaling.accept().await.expect("connection must arrive");
        let _socket = accept_hdr_async(stream, select_signaling_subprotocol)
            .await
            .expect("WebSocket handshake must complete");
        let _ = accepted_sender.send(());
        std::future::pending::<()>().await;
    });
    let remote = RemoteRuntimeConfig::new(endpoint, IceTransportPolicy::All, Vec::new())
        .expect("loopback signaling config must validate");
    let running = AgentRuntime::start_with_store(
        &fixture.config().with_remote(remote),
        fixture.secret_store.as_ref(),
    )
    .expect("Agent with remote runtime must start");
    timeout(IO_TIMEOUT, accepted_receiver)
        .await
        .expect("signaling handshake must not time out")
        .expect("signaling handshake must complete");

    timeout(IO_TIMEOUT, running.shutdown())
        .await
        .expect("shutdown must cancel registration")
        .expect("Agent must stop cleanly");
    server.abort();
    assert_runtime_artifacts_absent(fixture.runtime_dir());
}

#[cfg(feature = "native-webrtc")]
#[allow(clippy::result_large_err, clippy::unnecessary_wraps)]
fn select_signaling_subprotocol(
    _request: &Request,
    mut response: Response,
) -> Result<Response, ErrorResponse> {
    response.headers_mut().insert(
        SEC_WEBSOCKET_PROTOCOL,
        HeaderValue::from_static("roammand-signaling.v1.protobuf"),
    );
    Ok(response)
}

struct Fixture {
    _temporary: TempDir,
    paths: RuntimePaths,
    secret_store: Arc<MemorySecretStore>,
}

impl Fixture {
    fn new() -> Self {
        let temporary = tempfile::tempdir().expect("temporary root must be created");
        let paths = RuntimePaths::from_roots(
            temporary.path().join("data"),
            temporary.path().join("runtime"),
        );
        Self {
            _temporary: temporary,
            paths,
            secret_store: Arc::new(MemorySecretStore::new()),
        }
    }

    fn config(&self) -> AgentRuntimeConfig {
        AgentRuntimeConfig::new(
            self.paths.clone(),
            "Lifecycle Test Host".to_owned(),
            DevicePlatform::Macos,
        )
    }

    fn runtime_dir(&self) -> &Path {
        self.paths.runtime_dir()
    }
}

struct TestClient {
    stream: UnixStream,
}

impl TestClient {
    async fn connect(runtime_dir: &Path) -> Self {
        let token_bytes: [u8; 32] = fs::read(runtime_dir.join("ipc-token.bin"))
            .expect("token must be readable")
            .try_into()
            .expect("token must have fixed length");
        let mut stream = UnixStream::connect(runtime_dir.join("host-agent.sock"))
            .await
            .expect("client must connect");
        let challenge = read_server_frame(&mut stream).await;
        let Some(local_ipc_server_frame::Payload::Challenge(challenge)) = challenge.payload else {
            panic!("first frame must be a challenge");
        };
        let instance_id: [u8; 16] = challenge
            .agent_instance_id
            .try_into()
            .expect("instance ID must have fixed length");
        let server_nonce: [u8; 32] = challenge
            .server_nonce
            .try_into()
            .expect("server nonce must have fixed length");
        let token = IpcToken::new(token_bytes);
        let authentication = LocalIpcClientFrame {
            protocol_version: Some(protocol_version()),
            request_id: "authenticate".to_owned(),
            payload: Some(local_ipc_client_frame::Payload::Authenticate(
                LocalIpcAuthenticate {
                    client_nonce: CLIENT_NONCE.to_vec(),
                    client_proof: client_proof(&token, &instance_id, &server_nonce, &CLIENT_NONCE)
                        .to_vec(),
                },
            )),
        };
        write_client_frame(&mut stream, &authentication).await;
        let authenticated = read_server_frame(&mut stream).await;
        let Some(local_ipc_server_frame::Payload::Authenticated(authenticated)) =
            authenticated.payload
        else {
            panic!("second frame must authenticate the server");
        };
        assert_eq!(
            authenticated.server_proof,
            server_proof(&token, &instance_id, &server_nonce, &CLIENT_NONCE)
        );
        Self { stream }
    }

    async fn host_identity(&mut self) -> DeviceIdentity {
        let response = self
            .request(local_ipc_client_frame::Payload::GetHostStatus(
                GetHostStatusRequest {},
            ))
            .await;
        let Some(local_ipc_server_frame::Payload::HostStatus(status)) = response.payload else {
            panic!("expected HostStatus response");
        };
        status.identity.expect("status must include identity")
    }

    async fn create_grant(&mut self, controller: DeviceIdentity) {
        let response = self
            .request(local_ipc_client_frame::Payload::CreateControllerGrant(
                CreateControllerGrantRequest {
                    controller: Some(controller),
                    permissions: vec![SessionPermission::ViewScreen as i32],
                },
            ))
            .await;
        assert!(matches!(
            response.payload,
            Some(local_ipc_server_frame::Payload::ControllerGrantCreated(_))
        ));
    }

    async fn pairing_status(&mut self) -> HostPairingStatusSnapshot {
        let response = self
            .request(local_ipc_client_frame::Payload::GetHostPairingStatus(
                GetHostPairingStatusRequest {},
            ))
            .await;
        let Some(local_ipc_server_frame::Payload::HostPairingStatus(status)) = response.payload
        else {
            panic!("expected HostPairingStatus response");
        };
        status
    }

    async fn grant_count(&mut self) -> usize {
        let response = self
            .request(local_ipc_client_frame::Payload::ListControllerGrants(
                ListControllerGrantsRequest {},
            ))
            .await;
        let Some(local_ipc_server_frame::Payload::ControllerGrantList(list)) = response.payload
        else {
            panic!("expected ControllerGrantList response");
        };
        list.grants.len()
    }

    async fn request(&mut self, payload: local_ipc_client_frame::Payload) -> LocalIpcServerFrame {
        let frame = LocalIpcClientFrame {
            protocol_version: Some(protocol_version()),
            request_id: "request".to_owned(),
            payload: Some(payload),
        };
        write_client_frame(&mut self.stream, &frame).await;
        read_server_frame(&mut self.stream).await
    }
}

async fn write_client_frame(stream: &mut UnixStream, frame: &LocalIpcClientFrame) {
    let encoded = encode_frame(&frame.encode_to_vec()).expect("frame must encode");
    timeout(IO_TIMEOUT, stream.write_all(&encoded))
        .await
        .expect("write must not time out")
        .expect("write must succeed");
}

async fn read_server_frame(stream: &mut UnixStream) -> LocalIpcServerFrame {
    let mut length = [0_u8; 4];
    timeout(IO_TIMEOUT, stream.read_exact(&mut length))
        .await
        .expect("length read must not time out")
        .expect("length read must succeed");
    let length = usize::try_from(u32::from_be_bytes(length)).expect("frame length must fit");
    let mut payload = vec![0_u8; length];
    timeout(IO_TIMEOUT, stream.read_exact(&mut payload))
        .await
        .expect("payload read must not time out")
        .expect("payload read must succeed");
    LocalIpcServerFrame::decode(payload.as_slice()).expect("server frame must decode")
}

fn controller() -> DeviceIdentity {
    let public_key = ed25519_dalek::SigningKey::from_bytes(&[0x72; 32])
        .verifying_key()
        .to_bytes();
    DeviceIdentity {
        device_id: derive_device_id_v1(&public_key)
            .expect("controller ID must derive")
            .to_vec(),
        public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
        public_key: public_key.to_vec(),
        display_name: "Lifecycle Controller".to_owned(),
        platform: DevicePlatform::Ios as i32,
    }
}

const fn protocol_version() -> ProtocolVersion {
    ProtocolVersion { major: 1, minor: 0 }
}

fn assert_runtime_artifacts_absent(runtime_dir: &Path) {
    for file_name in ["host-agent.sock", "ipc-token.bin", "ipc-endpoint.txt"] {
        assert!(
            !runtime_dir.join(file_name).exists(),
            "{file_name} must be removed"
        );
    }
}
