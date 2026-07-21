<!-- SPDX-License-Identifier: Apache-2.0 -->

# Licensing

Roammand is a multi-license repository. There is no single repository-wide
license: the destination path and the file's SPDX identifier determine the
terms for project-authored material.

| Path | License |
| --- | --- |
| `apps/client_flutter/` | Mozilla Public License 2.0 |
| `crates/` | Mozilla Public License 2.0 |
| `services/signaling/` | GNU Affero General Public License v3.0 only |
| `schema/` | Apache License 2.0 |
| `gen/` | Apache License 2.0 |
| `conformance/` | Apache License 2.0 |
| `docs/`, root public documentation, and `brand/*.md` | Apache License 2.0 |
| Project-authored `infra/`, `packaging/`, and `scripts/` files carrying an Apache-2.0 SPDX identifier | Apache License 2.0 |

Full license texts are stored in `licenses/`. Project-authored source files carry the matching SPDX identifier; generated scaffolding inherits the license of its component path.

A third-party file, generated artifact, or embedded notice keeps its own terms
even when located under one of these paths. The repository does not currently
state a standalone copyright/trademark policy for the visual brand assets; ask
the maintainer before redistributing those assets independently.

Dependencies and bundled third-party assets retain their own licenses. A component license does not replace third-party notices.

## Dependency inventory and release notices

The dependency tables below highlight native, cryptographic, pairing, and
bundled assets that need special attention. They are **not** an exhaustive
third-party notice report. Resolution and integrity inputs include:

- `Cargo.lock` for Rust;
- `apps/client_flutter/pubspec.lock` and the Apple `Podfile.lock` files for
  Flutter and CocoaPods;
- each Go module's `go.mod` and `go.sum` files;
- the checked hashes and embedded `LICENSE.md` files from native WebRTC archives.

Cargo, pub, and CocoaPods lockfiles record selected versions and integrity
inputs. A Go `go.sum` is a checksum history, not an exact inventory of the
currently selected module graph; derive that graph from each module (for
example, with `go list -m -json all`). None of these inputs substitutes for
license texts or attribution. Before distributing an application, installer,
container, or hosted modified signaling service:

1. Generate a complete software bill of materials and third-party notice list
   from the exact locked graph and the artifacts actually shipped.
2. Review direct and transitive packages, the Flutter engine/embedders,
   CocoaPods, native WebRTC archives, container base images, and bundled assets.
3. Include every required license, notice, attribution, source offer, and
   modification notice in the distribution or accompanying source location.
4. Treat an unknown or incompatible license and a missing required notice as a
   release blocker.

The current package scripts stage the project license texts and the fetched
native WebRTC archive notices. That technical allowlist must not be interpreted
as proof that the complete transitive third-party notice set or SBOM has been
generated and reviewed.

## Highlighted WebRTC dependencies

| Dependency or asset | Upstream license/notice location | Distribution note |
| --- | --- | --- |
| `flutter_webrtc` 1.5.2 | `LICENSE` and `NOTICE` in the resolved pub package | MIT, with additional upstream notices that must accompany redistributed binaries as applicable |
| `libwebrtc` 0.3.27 Rust wrapper | License metadata in the resolved Cargo package | Retain the Cargo package's upstream license terms |
| Pinned native WebRTC archives | `LICENSE.md` inside each archive fetched by `scripts/fetch_libwebrtc.sh` | WebRTC BSD-style terms plus included third-party terms; reproduce applicable notices with binary distributions |

The native WebRTC archives are downloaded from the pinned upstream release and are not committed to this repository. Their release tag and SHA-256 values are recorded in `scripts/libwebrtc-assets.sha256`. Packagers are responsible for preserving the complete upstream `LICENSE.md` from the exact archive they redistribute.

## Highlighted pairing dependencies and assets

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
| Dart `url_launcher` 6.3.2 and `package_info_plus` 10.2.1 | `LICENSE` in each resolved pub package | BSD-3-Clause |

The BIP-39 notice is committed at
[`conformance/wordlists/NOTICE.md`](conformance/wordlists/NOTICE.md). Version
numbers above describe the locked dependency graph at the time this overview
was updated; release tooling must derive its inventory from the ecosystem's
selected graph and the artifacts actually shipped rather than relying on this
prose.

This file summarizes repository intent and does not replace legal review for a
particular distribution or hosted deployment.
