<!-- SPDX-License-Identifier: Apache-2.0 -->

# Licensing

Components are licensed by path:

| Path | License |
| --- | --- |
| `apps/client_flutter/` | Mozilla Public License 2.0 |
| `crates/` | Mozilla Public License 2.0 |
| `services/signaling/` | GNU Affero General Public License v3.0 only |
| `schema/` | Apache License 2.0 |
| `gen/` | Apache License 2.0 |
| `conformance/` | Apache License 2.0 |
| Public technical documentation | Apache License 2.0 |

Full license texts are stored in `licenses/`. Project-authored source files carry the matching SPDX identifier; generated scaffolding inherits the license of its component path.

Dependencies and bundled third-party assets retain their own licenses. A component license does not replace third-party notices.

## WebRTC dependencies

| Dependency or asset | Upstream license/notice location | Distribution note |
| --- | --- | --- |
| `flutter_webrtc` 1.5.2 | `LICENSE` and `NOTICE` in the resolved pub package | MIT, with additional upstream notices that must accompany redistributed binaries as applicable |
| `libwebrtc` 0.3.27 Rust wrapper | License metadata in the resolved Cargo package | Retain the Cargo package's upstream license terms |
| Pinned native WebRTC archives | `LICENSE.md` inside each archive fetched by `scripts/fetch_libwebrtc.sh` | WebRTC BSD-style terms plus included third-party terms; reproduce applicable notices with binary distributions |

The native WebRTC archives are downloaded from the pinned upstream release and are not committed to this repository. Their release tag and SHA-256 values are recorded in `scripts/libwebrtc-assets.sha256`. Packagers are responsible for preserving the complete upstream `LICENSE.md` from the exact archive they redistribute.

## Pairing dependencies and assets

| Dependency or asset | Upstream license/notice location | Distribution note |
| --- | --- | --- |
| BIP-39 English word list | `conformance/wordlists/NOTICE.md` | MIT; vendored unchanged with a pinned SHA-256 for four-word SAS interoperability |
| Dart `cryptography` 2.9.0 | `LICENSE` in the resolved pub package | Apache-2.0 |
| Rust `aes-gcm` 0.10.3 and `hkdf` 0.12.4 | License metadata and files in the resolved Cargo packages | Apache-2.0 OR MIT |
| Rust `x25519-dalek` 2.0.1 | License metadata and files in the resolved Cargo package | BSD-3-Clause |
| Dart `mobile_scanner` 7.2.0 | `LICENSE` in the resolved pub package | BSD-3-Clause; preserve notices in redistributed mobile binaries |
| Dart `qr_flutter` 4.1.0 | `LICENSE` in the resolved pub package | BSD-3-Clause |
| Dart `flutter_secure_storage` 10.3.1 | `LICENSE` in the resolved pub package | BSD-3-Clause |
| Dart `device_info_plus` 13.2.0 and `path_provider` 2.1.6 | `LICENSE` in each resolved pub package | BSD-3-Clause |
