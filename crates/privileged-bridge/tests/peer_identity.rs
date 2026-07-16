// SPDX-License-Identifier: MPL-2.0

use roammand_privileged_bridge::peer_identity::{
    ExecutableEvidence, PeerIdentityError, PeerIdentityEvidence, PeerPrincipal, PeerRole,
    validate_peer_identity,
};

fn valid_evidence() -> PeerIdentityEvidence {
    PeerIdentityEvidence {
        role: PeerRole::SessionHelper,
        local_transport: true,
        process_id: Some(700),
        principal: Some(PeerPrincipal::Unix {
            actual_uid: 501,
            expected_uid: 501,
        }),
        os_session_id: Some(501),
        expected_os_session_id: 501,
        executable: Some(ExecutableEvidence {
            absolute: true,
            installed_location: true,
            trusted_owner: true,
            immutable_parent_directories: true,
            actual_sha256: Some([0x31; 32]),
            manifest_sha256: [0x31; 32],
            signing_identity_matches: Some(true),
            signing_identity_required: true,
        }),
    }
}

#[test]
fn accepts_only_complete_local_installed_peer_evidence() {
    let verified = validate_peer_identity(&valid_evidence()).expect("valid evidence");
    assert_eq!(verified.role(), PeerRole::SessionHelper);
    assert_eq!(verified.os_session_id(), 501);
}

#[test]
fn every_missing_or_mismatched_trust_gate_rejects() {
    let mut cases = Vec::new();
    let mut remote = valid_evidence();
    remote.local_transport = false;
    cases.push(remote);
    let mut no_pid = valid_evidence();
    no_pid.process_id = None;
    cases.push(no_pid);
    let mut no_principal = valid_evidence();
    no_principal.principal = None;
    cases.push(no_principal);
    let mut wrong_principal = valid_evidence();
    wrong_principal.principal = Some(PeerPrincipal::Unix {
        actual_uid: 502,
        expected_uid: 501,
    });
    cases.push(wrong_principal);
    let mut wrong_session = valid_evidence();
    wrong_session.os_session_id = Some(502);
    cases.push(wrong_session);
    let mut no_executable = valid_evidence();
    no_executable.executable = None;
    cases.push(no_executable);
    let mut relative = valid_evidence();
    relative.executable.as_mut().expect("executable").absolute = false;
    cases.push(relative);
    let mut mutable_parent = valid_evidence();
    mutable_parent
        .executable
        .as_mut()
        .expect("executable")
        .immutable_parent_directories = false;
    cases.push(mutable_parent);
    let mut wrong_hash = valid_evidence();
    wrong_hash
        .executable
        .as_mut()
        .expect("executable")
        .actual_sha256 = Some([0x32; 32]);
    cases.push(wrong_hash);
    let mut unsigned = valid_evidence();
    unsigned
        .executable
        .as_mut()
        .expect("executable")
        .signing_identity_matches = Some(false);
    cases.push(unsigned);

    for evidence in cases {
        assert!(validate_peer_identity(&evidence).is_err());
    }
}

#[test]
fn debug_and_errors_do_not_expose_peer_evidence() {
    let evidence = valid_evidence();
    let debug = format!("{evidence:?}");
    for sensitive in ["700", "501", "313131", "actual_uid", "sha256"] {
        assert!(
            !debug.contains(sensitive),
            "debug leaked {sensitive}: {debug}"
        );
    }
    assert_eq!(
        debug,
        "PeerIdentityEvidence { role: SessionHelper, gates: [REDACTED] }"
    );
    assert_eq!(
        format!("{}", PeerIdentityError::Rejected),
        "peer identity rejected"
    );
}
