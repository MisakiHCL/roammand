#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Contract tests for exact Cargo notice fallbacks."""

from __future__ import annotations

import json
import pathlib
import shutil
import sys
import tempfile
from collections.abc import Callable

REPO_ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

from macos_release_compliance.collectors import (  # noqa: E402
    copyright_text_from_notices,
)
from macos_release_compliance.model import ComplianceError, Notice  # noqa: E402
from macos_release_compliance.vetted_cargo_notices import (  # noqa: E402
    vetted_identities,
    vetted_notice_for_package,
)

BLOCK2_REVISION = "b4167b582b2f75f9a1be75495c41b765344fd03c"
BLOCK2_REPOSITORY = "https://github.com/madsmtm/objc2"


def expect_failure(expected: str, action: Callable[[], object]) -> None:
    try:
        action()
    except ComplianceError as error:
        if expected not in str(error):
            raise AssertionError(
                f"expected failure containing {expected!r}, got {error!r}"
            ) from error
    else:
        raise AssertionError(f"expected failure containing {expected!r}")


def write_vcs_revision(package_root: pathlib.Path, revision: str) -> None:
    (package_root / ".cargo_vcs_info.json").write_text(
        json.dumps({"git": {"sha1": revision}, "path_in_vcs": "crates/block2"}),
        encoding="utf-8",
    )


def main() -> None:
    identities = vetted_identities()
    assert len(identities) == 23
    assert len(set(identities)) == len(identities)
    assert (
        copyright_text_from_notices(
            (
                Notice(
                    "Apache template",
                    "copyright notice that is included in the work\n"
                    "Copyright [yyyy] [name of copyright owner]\n",
                ),
            )
        )
        == "NOASSERTION"
    )
    assert (
        copyright_text_from_notices(
            (Notice("MIT", "Copyright (c) 2020 Example Authors\n"),)
        )
        == "Copyright (c) 2020 Example Authors"
    )

    with tempfile.TemporaryDirectory(prefix="roammand-vetted-cargo-") as raw_temp:
        root = pathlib.Path(raw_temp)
        package_root = root / "cargo-cache/block2-0.6.2"
        package_root.mkdir(parents=True)
        manifest = package_root / "Cargo.toml"
        manifest.write_text("[package]\nname='block2'\nversion='0.6.2'\n")
        write_vcs_revision(package_root, BLOCK2_REVISION)

        for relative_path in (
            "scripts/macos_release_compliance/vetted_notices/objc2-LICENSE.md",
            "licenses/MIT.txt",
        ):
            source = REPO_ROOT / relative_path
            destination = root / relative_path
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)

        entry, notices = vetted_notice_for_package(
            root,
            name="block2",
            version="0.6.2",
            repository=BLOCK2_REPOSITORY,
            manifest_path=manifest,
            license_declared="MIT",
        )
        assert entry.license_concluded == "MIT"
        assert entry.copyright_text == "NOASSERTION"
        assert entry.source_url.endswith(BLOCK2_REVISION)
        assert len(notices) == 2

        write_vcs_revision(package_root, "a" * 40)
        expect_failure(
            "no exact vetted fallback",
            lambda: vetted_notice_for_package(
                root,
                name="block2",
                version="0.6.2",
                repository=BLOCK2_REPOSITORY,
                manifest_path=manifest,
                license_declared="MIT",
            ),
        )

        write_vcs_revision(package_root, BLOCK2_REVISION)
        expect_failure(
            "no exact vetted fallback",
            lambda: vetted_notice_for_package(
                root,
                name="block2",
                version="0.6.3",
                repository=BLOCK2_REPOSITORY,
                manifest_path=manifest,
                license_declared="MIT",
            ),
        )

        expect_failure(
            "no exact vetted fallback",
            lambda: vetted_notice_for_package(
                root,
                name="unknown-crate",
                version="1.0.0",
                repository="https://example.test/unknown-crate",
                manifest_path=manifest,
                license_declared="MIT",
            ),
        )

        (root / "licenses/MIT.txt").write_text("tampered\n", encoding="utf-8")
        expect_failure(
            "vetted notice content has changed",
            lambda: vetted_notice_for_package(
                root,
                name="block2",
                version="0.6.2",
                repository=BLOCK2_REPOSITORY,
                manifest_path=manifest,
                license_declared="MIT",
            ),
        )

    print("vetted Cargo notice contract ok")


if __name__ == "__main__":
    main()
