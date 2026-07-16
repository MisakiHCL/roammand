// SPDX-License-Identifier: MPL-2.0

use roammand_privileged_bridge::lease::{
    AcquireLease, LEASE_DURATION_MS, LeaseError, LeaseId, LeaseIdSource, LeaseManager,
    RENEW_INTERVAL_MS, SessionId,
};

#[derive(Debug)]
struct FixedIds(u8);

impl LeaseIdSource for FixedIds {
    fn next_lease_id(&mut self) -> Result<LeaseId, LeaseError> {
        let value = self.0;
        self.0 = self.0.wrapping_add(1);
        Ok(LeaseId::new([value; 16]))
    }
}

fn request(generation: u64) -> AcquireLease {
    AcquireLease {
        session_id: SessionId::new([0x44; 16]),
        generation,
        controller_display_name: "My phone".to_owned(),
        may_control_input: true,
    }
}

#[test]
fn requires_one_host_and_only_one_active_random_lease() {
    let mut manager = LeaseManager::new([0x11; 16]);
    let mut ids = FixedIds(0x21);

    assert_eq!(
        manager.acquire(request(7), 1_000, &mut ids),
        Err(LeaseError::HostDisconnected)
    );
    manager.connect_host(7).expect("connect host");
    assert_eq!(
        manager.connect_host(7),
        Err(LeaseError::HostAlreadyConnected)
    );

    let lease = manager
        .acquire(request(7), 1_000, &mut ids)
        .expect("acquire lease");
    assert_eq!(lease.id(), LeaseId::new([0x21; 16]));
    assert_eq!(lease.expires_at_ms(), 1_000 + LEASE_DURATION_MS);
    assert_eq!(
        manager.acquire(request(7), 1_001, &mut ids),
        Err(LeaseError::LeaseAlreadyActive)
    );
    assert_eq!(format!("{:?}", lease.id()), "LeaseId([REDACTED; 16])");
    let lease_debug = format!("{lease:?}");
    assert!(!lease_debug.contains("My phone"));
    assert!(!lease_debug.contains("33, 33"));
    let manager_debug = format!("{manager:?}");
    assert!(!manager_debug.contains("17, 17"));
    assert!(!manager_debug.contains("My phone"));
}

#[test]
fn renewal_is_bounded_to_five_second_cadence_and_fifteen_second_expiry() {
    let mut manager = LeaseManager::new([0x11; 16]);
    let mut ids = FixedIds(0x31);
    manager.connect_host(3).expect("connect host");
    let lease = manager.acquire(request(3), 2_000, &mut ids).expect("lease");

    assert_eq!(
        manager.renew(lease.id(), 3, 2_000 + RENEW_INTERVAL_MS - 1),
        Err(LeaseError::RenewedTooSoon)
    );
    let renewed = manager
        .renew(lease.id(), 3, 2_000 + RENEW_INTERVAL_MS)
        .expect("renew");
    assert_eq!(
        renewed.expires_at_ms(),
        2_000 + RENEW_INTERVAL_MS + LEASE_DURATION_MS
    );
    assert_eq!(manager.expire(renewed.expires_at_ms() - 1), None);
    assert_eq!(manager.expire(renewed.expires_at_ms()), Some(lease.id()));
    assert!(!manager.input_may_be_enabled());
}

#[test]
fn rejects_stale_generation_and_non_increasing_command_sequences() {
    let mut manager = LeaseManager::new([0x11; 16]);
    let mut ids = FixedIds(0x41);
    manager.connect_host(9).expect("connect host");
    assert_eq!(
        manager.acquire(request(8), 1_000, &mut ids),
        Err(LeaseError::StaleGeneration)
    );
    let lease = manager.acquire(request(9), 1_000, &mut ids).expect("lease");

    assert_eq!(manager.authorize_command(lease.id(), 9, 1, 1_001), Ok(()));
    assert_eq!(
        manager.authorize_command(lease.id(), 9, 1, 1_002),
        Err(LeaseError::InvalidSequence)
    );
    assert_eq!(
        manager.authorize_command(lease.id(), 8, 2, 1_002),
        Err(LeaseError::StaleGeneration)
    );
    assert_eq!(manager.authorize_command(lease.id(), 9, 2, 1_002), Ok(()));
}

#[test]
fn release_close_and_disconnect_are_idempotent_and_freeze_input_first() {
    let mut manager = LeaseManager::new([0x11; 16]);
    let mut ids = FixedIds(0x51);
    manager.connect_host(4).expect("connect host");
    let lease = manager.acquire(request(4), 1_000, &mut ids).expect("lease");

    assert!(manager.release(lease.id(), 4).expect("release"));
    assert!(!manager.input_may_be_enabled());
    assert!(!manager.release(lease.id(), 4).expect("release twice"));
    assert!(!manager.close(lease.id(), 4).expect("close after release"));
    assert!(!manager.disconnect_host());
    assert!(!manager.disconnect_host());
}
