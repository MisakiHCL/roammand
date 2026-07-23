# SPDX-License-Identifier: Apache-2.0
"""Exact, reviewable notice fallbacks for crates that omit packaged notices.

Every entry is tied to the published crate name/version, normalized repository
URL, and the Git revision recorded by Cargo in `.cargo_vcs_info.json`.  This is
intentionally a closed allow-list: a new crate version must carry its own
LICENSE/NOTICE files or receive a separate review and mapping here.
"""

from __future__ import annotations

import dataclasses
import pathlib
from collections.abc import Sequence

from .model import Notice, fail, load_json, normalized_url, read_text, sha256_file


@dataclasses.dataclass(frozen=True)
class VettedFile:
    relative_path: str
    expected_sha256: str
    label: str


@dataclasses.dataclass(frozen=True)
class VettedCargoNotice:
    name: str
    version: str
    repository: str
    revision: str
    license_declared: str
    license_concluded: str
    copyright_text: str
    files: tuple[VettedFile, ...]
    source_url_override: str = ""

    @property
    def source_url(self) -> str:
        return self.source_url_override or f"{self.repository}/tree/{self.revision}"


OBJC2_ROOT_LICENSE = VettedFile(
    "scripts/macos_release_compliance/vetted_notices/objc2-LICENSE.md",
    "7f976f7e9cb2d87df7230606feb932c3f21ac0e664045a775b600046ff850c54",
    "objc2 repository LICENSE.md",
)
CANONICAL_MIT = VettedFile(
    "licenses/MIT.txt",
    "508a77d2e7b51d98adeed32648ad124b7b30241a8e70b2e72c99f92d8e5874d1",
    "MIT License",
)
CANONICAL_APACHE = VettedFile(
    "licenses/Apache-2.0.txt",
    "cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30",
    "Apache License 2.0",
)
PBJSON_LICENSE = VettedFile(
    "scripts/macos_release_compliance/vetted_notices/pbjson-LICENSE",
    "791a00933f2ea7e512856361e026998362241c3918d7be948c24d29441033b55",
    "pbjson repository LICENSE",
)
LIVEKIT_LICENSE = VettedFile(
    "scripts/macos_release_compliance/vetted_notices/livekit-LICENSE",
    "c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4",
    "LiveKit repository LICENSE",
)
LIVEKIT_NOTICE = VettedFile(
    "scripts/macos_release_compliance/vetted_notices/livekit-NOTICE",
    "6d0f7c5e0deb284362296c5da110dd353831da2e67ca77cb5abc051b951b0fac",
    "LiveKit repository NOTICE",
)
WEBRTC_SYS_NOTICE = VettedFile(
    "scripts/macos_release_compliance/vetted_notices/webrtc-sys-NOTICE.md",
    "f5ca7494896aefbe0f5746a24c2cd3a5bda147e164b7b5efb0267d9f0652cb06",
    "LiveKit webrtc-sys third-party NOTICE",
)
LIVEKIT_PROTOCOL_LICENSE = VettedFile(
    "licenses/Apache-2.0.txt",
    "cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30",
    "LiveKit protocol submodule LICENSE",
)
PROST_LICENSE = VettedFile(
    "scripts/macos_release_compliance/vetted_notices/prost-LICENSE",
    "a60eea817514531668d7e00765731449fe14d059d3249e0bc93b36de45f759f2",
    "prost repository LICENSE",
)


def objc2_entry(
    name: str,
    version: str,
    revision: str,
    license_declared: str,
    *,
    mit_only: bool,
) -> VettedCargoNotice:
    return VettedCargoNotice(
        name=name,
        version=version,
        repository="https://github.com/madsmtm/objc2",
        revision=revision,
        license_declared=license_declared,
        license_concluded="MIT" if mit_only else "Apache-2.0",
        # The immutable upstream LICENSE.md states the applicable terms but
        # does not identify a copyright holder. Do not infer one from authors.
        copyright_text="NOASSERTION",
        files=(
            OBJC2_ROOT_LICENSE,
            CANONICAL_MIT if mit_only else CANONICAL_APACHE,
        ),
    )


def livekit_entry(
    name: str,
    version: str,
    revision: str,
    *,
    files: tuple[VettedFile, ...] = (LIVEKIT_LICENSE, LIVEKIT_NOTICE),
    source_url_override: str = "",
) -> VettedCargoNotice:
    return VettedCargoNotice(
        name=name,
        version=version,
        repository="https://github.com/livekit/rust-sdks",
        revision=revision,
        license_declared="Apache-2.0",
        license_concluded="Apache-2.0",
        copyright_text="Copyright 2023 LiveKit, Inc.",
        files=files,
        source_url_override=source_url_override,
    )


VETTED_CARGO_NOTICES: tuple[VettedCargoNotice, ...] = (
    objc2_entry(
        "block2",
        "0.6.2",
        "b4167b582b2f75f9a1be75495c41b765344fd03c",
        "MIT",
        mit_only=True,
    ),
    objc2_entry(
        "dispatch2",
        "0.3.1",
        "8852b424193ca41602281b3d7540d7c8ed51e49a",
        "Zlib OR Apache-2.0 OR MIT",
        mit_only=False,
    ),
    objc2_entry(
        "objc2",
        "0.6.4",
        "8852b424193ca41602281b3d7540d7c8ed51e49a",
        "MIT",
        mit_only=True,
    ),
    objc2_entry(
        "objc2-encode",
        "4.1.0",
        "8d214f5477365ffcbcbb7de058c86ed9a518efb7",
        "MIT",
        mit_only=True,
    ),
    objc2_entry(
        "objc2-foundation",
        "0.3.2",
        "7b1abfd750a2cacaea71d6a56ecfb83cb7de560b",
        "MIT",
        mit_only=True,
    ),
    *(
        objc2_entry(
            name,
            "0.3.2",
            "7b1abfd750a2cacaea71d6a56ecfb83cb7de560b",
            "Zlib OR Apache-2.0 OR MIT",
            mit_only=False,
        )
        for name in (
            "objc2-app-kit",
            "objc2-cloud-kit",
            "objc2-core-data",
            "objc2-core-foundation",
            "objc2-core-graphics",
            "objc2-core-image",
            "objc2-core-text",
            "objc2-core-video",
            "objc2-io-surface",
            "objc2-quartz-core",
        )
    ),
    VettedCargoNotice(
        name="pbjson",
        version="0.6.0",
        repository="https://github.com/influxdata/pbjson",
        revision="255585bb5f006cf7a5c39e75bfd66a3615cff6c2",
        license_declared="MIT",
        license_concluded="MIT",
        copyright_text="Copyright (c) 2020 InfluxData",
        files=(PBJSON_LICENSE,),
    ),
    VettedCargoNotice(
        name="pbjson-build",
        version="0.6.2",
        repository="https://github.com/influxdata/pbjson",
        revision="28b363c0b938f4688efa0414a1b032bec59f970c",
        license_declared="MIT",
        license_concluded="MIT",
        copyright_text="Copyright (c) 2020 InfluxData",
        files=(PBJSON_LICENSE,),
    ),
    VettedCargoNotice(
        name="pbjson-types",
        version="0.6.0",
        repository="https://github.com/influxdata/pbjson",
        revision="255585bb5f006cf7a5c39e75bfd66a3615cff6c2",
        license_declared="MIT",
        license_concluded="MIT",
        copyright_text="Copyright (c) 2020 InfluxData",
        files=(PBJSON_LICENSE,),
    ),
    livekit_entry(
        "libwebrtc",
        "0.3.27",
        "20e442edab8e91f399ca62e0f5d811ed0002a4b2",
        files=(LIVEKIT_LICENSE, LIVEKIT_NOTICE, WEBRTC_SYS_NOTICE),
    ),
    livekit_entry(
        "livekit-protocol",
        "0.7.2",
        "20e442edab8e91f399ca62e0f5d811ed0002a4b2",
        files=(LIVEKIT_PROTOCOL_LICENSE, LIVEKIT_NOTICE),
        source_url_override=(
            "https://github.com/livekit/protocol/tree/"
            "f734574de339d94dd83f70fbe1723ba1cdc61c2f"
        ),
    ),
    livekit_entry(
        "webrtc-sys-build",
        "0.3.14",
        "20e442edab8e91f399ca62e0f5d811ed0002a4b2",
        files=(LIVEKIT_LICENSE, LIVEKIT_NOTICE, WEBRTC_SYS_NOTICE),
    ),
    livekit_entry(
        "livekit-runtime",
        "0.4.0",
        "afecf6f25e77fdfa8c7eb5047990f5983a766f87",
    ),
    VettedCargoNotice(
        name="prost",
        version="0.12.6",
        repository="https://github.com/tokio-rs/prost",
        revision="d42c85e790263f78f6c626ceb0dac5fda0edcb41",
        license_declared="Apache-2.0",
        license_concluded="Apache-2.0",
        copyright_text="NOASSERTION",
        files=(PROST_LICENSE,),
    ),
)


VETTED_BY_IDENTITY = {
    (entry.name, entry.version, entry.repository, entry.revision): entry
    for entry in VETTED_CARGO_NOTICES
}


def cargo_vcs_revision(manifest_path: pathlib.Path, component_name: str) -> str:
    vcs_path = manifest_path.parent / ".cargo_vcs_info.json"
    document = load_json(vcs_path, f"Cargo VCS metadata for {component_name}")
    git = document.get("git")
    revision = str(git.get("sha1") or "") if isinstance(git, dict) else ""
    if len(revision) != 40 or any(character not in "0123456789abcdef" for character in revision):
        raise fail(f"Cargo VCS metadata for {component_name} has no full Git revision")
    return revision


def vetted_notice_for_package(
    repo_root: pathlib.Path,
    *,
    name: str,
    version: str,
    repository: str,
    manifest_path: pathlib.Path,
    license_declared: str,
) -> tuple[VettedCargoNotice, tuple[Notice, ...]]:
    repository = normalized_url(repository).rstrip("/")
    revision = cargo_vcs_revision(manifest_path, name)
    entry = VETTED_BY_IDENTITY.get((name, version, repository, revision))
    if entry is None:
        raise fail(
            "Cargo package "
            f"{name} {version} has no packaged LICENSE/NOTICE and no exact vetted "
            f"fallback for repository {repository or '<missing>'} at {revision}"
        )
    if license_declared != entry.license_declared:
        raise fail(
            f"Cargo package {name} declared license differs from its vetted mapping"
        )
    notices: list[Notice] = []
    for file in entry.files:
        path = repo_root / file.relative_path
        actual_sha256 = sha256_file(path)
        if actual_sha256 != file.expected_sha256:
            raise fail(
                f"vetted notice content has changed for Cargo package {name}: "
                f"{file.relative_path}"
            )
        notices.append(Notice(file.label, read_text(path, file.label)))
    return entry, tuple(notices)


def vetted_identities() -> Sequence[tuple[str, str, str, str]]:
    """Return stable identities for contract tests and review tooling."""

    return tuple(sorted(VETTED_BY_IDENTITY))
