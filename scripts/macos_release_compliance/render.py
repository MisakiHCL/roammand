# SPDX-License-Identifier: Apache-2.0
"""SPDX and human-readable compliance document rendering."""

from __future__ import annotations

import argparse
import datetime as dt
import os
import pathlib
import re
import shutil
import tempfile
import urllib.parse
from collections.abc import Sequence
from typing import Any

from .model import (
    OUTPUT_NAMES,
    SOURCE_DATE_ENVIRONMENT_VARIABLE,
    SPDX_LICENSE_REF_TOKEN,
    Component,
    FlutterMetadata,
    Notice,
    PackageMetadata,
    ShippedFileInventory,
    fail,
    sha256_text,
)


def spdx_package(component: Component) -> dict[str, Any]:
    package: dict[str, Any] = {
        "SPDXID": component.spdx_id,
        "name": component.name,
        "versionInfo": component.version,
        "downloadLocation": component.download_location or "NOASSERTION",
        "filesAnalyzed": False,
        "licenseConcluded": component.license_concluded,
        "licenseDeclared": component.license_declared,
        "copyrightText": component.copyright_text,
        "supplier": "NOASSERTION",
        "originator": "NOASSERTION",
        "sourceInfo": component.source_url,
    }
    if component.summary:
        package["summary"] = component.summary
    if component.checksum and re.fullmatch(
        r"(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})", component.checksum
    ):
        algorithm = "SHA1" if len(component.checksum) == 40 else "SHA256"
        package["checksums"] = [
            {"algorithm": algorithm, "checksumValue": component.checksum.lower()}
        ]
    if component.purl:
        package["externalRefs"] = [
            {
                "referenceCategory": "PACKAGE-MANAGER",
                "referenceType": "purl",
                "referenceLocator": component.purl,
            }
        ]
    return package


def extracted_licenses(components: Sequence[Component]) -> list[dict[str, Any]]:
    extracted: dict[str, dict[str, Any]] = {}
    for component in components:
        raw_license_refs = re.findall(
            r"LicenseRef-[A-Za-z0-9._-]+", component.license_declared
        )
        invalid_refs = [
            license_ref
            for license_ref in raw_license_refs
            if SPDX_LICENSE_REF_TOKEN.fullmatch(license_ref) is None
        ]
        if invalid_refs:
            raise fail(
                f"{component.name} uses an invalid SPDX license reference: "
                f"{invalid_refs[0]}"
            )
        license_refs = SPDX_LICENSE_REF_TOKEN.findall(component.license_declared)
        for license_ref in license_refs:
            notice = component.notices[0] if component.notices else None
            if notice is None:
                raise fail(f"{component.name} uses {license_ref} without license text")
            extracted.setdefault(
                license_ref,
                {
                    "licenseId": license_ref,
                    "extractedText": notice.text.rstrip(),
                    "name": notice.label,
                    "seeAlsos": [component.source_url]
                    if component.source_url.startswith("https://")
                    else [],
                },
            )
    return [extracted[key] for key in sorted(extracted)]


def created_timestamp() -> str:
    raw_epoch = os.environ.get(SOURCE_DATE_ENVIRONMENT_VARIABLE)
    if raw_epoch is None:
        return (
            dt.datetime.now(tz=dt.timezone.utc)
            .replace(microsecond=0)
            .isoformat()
            .replace("+00:00", "Z")
        )
    try:
        epoch = int(raw_epoch)
    except ValueError as error:
        raise fail(f"{SOURCE_DATE_ENVIRONMENT_VARIABLE} must be an integer") from error
    if epoch < 0:
        raise fail(f"{SOURCE_DATE_ENVIRONMENT_VARIABLE} must not be negative")
    return (
        dt.datetime.fromtimestamp(epoch, tz=dt.timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )


def build_spdx_document(
    metadata: PackageMetadata,
    components: Sequence[Component],
    inventory: ShippedFileInventory,
    source_inputs: dict[str, str],
    created: str,
    arguments: argparse.Namespace,
) -> dict[str, Any]:
    brand_license_refs = sorted(
        {
            license_ref
            for component in components
            if component.ecosystem == "project-asset"
            for license_ref in SPDX_LICENSE_REF_TOKEN.findall(
                component.license_declared
            )
        }
    )
    root_license = " AND ".join(
        ("MPL-2.0", "Apache-2.0", *brand_license_refs)
    )
    source_input_manifest = "\n".join(
        f"{digest}  {path}" for path, digest in sorted(source_inputs.items())
    )
    source_input_digest = (
        sha256_text(source_input_manifest + "\n") if source_inputs else "not-recorded"
    )
    root_package = {
        "SPDXID": "SPDXRef-Package-Roammand",
        "name": "Roammand",
        "versionInfo": metadata.version,
        "supplier": f"Person: {arguments.copyright_holder}",
        "originator": f"Person: {arguments.copyright_holder}",
        "downloadLocation": "NOASSERTION",
        "filesAnalyzed": True,
        "packageVerificationCode": {
            "packageVerificationCodeValue": inventory.verification_code,
            "packageVerificationCodeExcludedFiles": list(inventory.excluded_files),
        },
        "licenseConcluded": "NOASSERTION",
        "licenseDeclared": root_license,
        "licenseInfoFromFiles": ["NOASSERTION"],
        "copyrightText": f"Copyright © {arguments.copyright_holder}",
        "sourceInfo": (
            f"{arguments.source_url} at commit {arguments.source_revision}; "
            f"bundle {metadata.bundle_identifier}, build {metadata.build}; "
            f"validated source-input manifest SHA-256: {source_input_digest}; "
            "the SHA-256 value identifies the staged payload inventory, not a "
            f"serialized .pkg file: {inventory.inventory_sha256}."
        ),
        "externalRefs": [
            {
                "referenceCategory": "PACKAGE-MANAGER",
                "referenceType": "purl",
                "referenceLocator": (
                    f"pkg:generic/roammand@{urllib.parse.quote(metadata.version)}"
                    "?os=macos"
                ),
            }
        ],
    }
    relationships = [
        {
            "spdxElementId": "SPDXRef-DOCUMENT",
            "relationshipType": "DESCRIBES",
            "relatedSpdxElement": "SPDXRef-Package-Roammand",
        },
        *inventory.relationships,
    ]
    for component in components:
        if component.relationship == "BUILD_DEPENDENCY_OF":
            relationships.append(
                {
                    "spdxElementId": component.spdx_id,
                    "relationshipType": "BUILD_DEPENDENCY_OF",
                    "relatedSpdxElement": "SPDXRef-Package-Roammand",
                }
            )
        else:
            relationships.append(
                {
                    "spdxElementId": "SPDXRef-Package-Roammand",
                    "relationshipType": component.relationship,
                    "relatedSpdxElement": component.spdx_id,
                }
            )
    component_manifest = "\n".join(
        "\t".join(
            (
                component.spdx_id,
                component.ecosystem,
                component.name,
                component.version,
                component.license_declared,
                component.license_concluded,
                component.checksum.lower(),
                component.relationship,
                component.source_url,
                component.purl,
                ",".join(
                    sorted(sha256_text(notice.text) for notice in component.notices)
                ),
            )
        )
        for component in sorted(components, key=lambda item: item.key)
    )
    component_graph_digest = sha256_text(component_manifest + "\n")
    namespace_seed = "\0".join(
        (
            metadata.bundle_identifier,
            metadata.version,
            metadata.build,
            arguments.source_revision,
            arguments.source_url,
            arguments.copyright_holder,
            inventory.inventory_sha256,
            source_input_digest,
            component_graph_digest,
            created,
        )
    )
    document: dict[str, Any] = {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"Roammand macOS {metadata.version} build {metadata.build}",
        "documentNamespace": (
            "https://spdx.org/spdxdocs/roammand-macos-"
            f"{metadata.version}-{metadata.build}-{arguments.source_revision}-"
            f"{sha256_text(namespace_seed)[:16]}"
        ),
        "creationInfo": {
            "created": created,
            "creators": [
                "Tool: Roammand macOS release compliance generator",
                f"Person: {arguments.copyright_holder}",
            ],
        },
        "documentDescribes": ["SPDXRef-Package-Roammand"],
        "packages": [root_package, *(spdx_package(item) for item in components)],
        "files": inventory.files,
        "relationships": relationships,
        "annotations": [
            {
                "annotationDate": created,
                "annotationType": "OTHER",
                "annotator": "Tool: Roammand macOS release compliance generator",
                "comment": (
                    "Automated provenance and inventory record for the exact "
                    "staged macOS payload. Volatile "
                    "self-referential compliance files and the install manifest "
                    "are listed as package verification-code exclusions. This "
                    "document does not claim a checksum for a serialized .pkg. "
                    + (
                        "Validated source inputs: " + source_input_manifest
                        if source_input_manifest
                        else "All fixture inputs were supplied explicitly; Git "
                        "tree source-input comparison was skipped."
                    )
                ),
            }
        ],
    }
    extracted = extracted_licenses(components)
    if extracted:
        document["hasExtractedLicensingInfos"] = extracted
    return document


def markdown_escape(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


def render_notices(
    metadata: PackageMetadata,
    components: Sequence[Component],
    package_digest: str,
    created: str,
    arguments: argparse.Namespace,
) -> str:
    lines = [
        "# Roammand macOS Third-Party Notices",
        "",
        f"- Product: Roammand {metadata.version} (build {metadata.build})",
        f"- Bundle identifier: `{metadata.bundle_identifier}`",
        f"- Source: {arguments.source_url}",
        f"- Source revision: `{arguments.source_revision}`",
        f"- Payload inventory SHA-256: `{package_digest}`",
        f"- Generated: {created}",
        f"- Project copyright holder: {arguments.copyright_holder}",
        "",
        (
            "This file applies only to the macOS payload identified above. "
            "Third-party copyrights and license terms remain with their "
            "respective owners."
        ),
        "",
        "## Component inventory",
        "",
        "| Ecosystem | Component | Version | License | Source |",
        "| --- | --- | --- | --- | --- |",
    ]
    for component in components:
        lines.append(
            "| "
            + " | ".join(
                (
                    markdown_escape(component.ecosystem),
                    markdown_escape(component.name),
                    markdown_escape(component.version),
                    markdown_escape(component.license_declared),
                    markdown_escape(component.source_url),
                )
            )
            + " |"
        )
    lines.extend(["", "## License and attribution texts", ""])
    grouped: dict[str, tuple[Notice, set[str]]] = {}
    for component in components:
        for notice in component.notices:
            digest = sha256_text(notice.text)
            if digest not in grouped:
                grouped[digest] = (notice, set())
            grouped[digest][1].add(f"{component.name} {component.version}")
    for digest, (notice, owners) in sorted(
        grouped.items(), key=lambda item: (item[1][0].label.lower(), item[0])
    ):
        lines.extend(
            [
                f"### {notice.label}",
                "",
                f"Applies to: {', '.join(sorted(owners))}",
                f"Text SHA-256: `{digest}`",
                "",
                notice.text.rstrip(),
                "",
                "---",
                "",
            ]
        )
    return "\n".join(lines).rstrip() + "\n"


def render_source_record(
    metadata: PackageMetadata,
    components: Sequence[Component],
    flutter: FlutterMetadata,
    native_tag: str,
    package_digest: str,
    source_inputs: dict[str, str],
    created: str,
    arguments: argparse.Namespace,
) -> str:
    sources: dict[str, set[str]] = {}
    for component in components:
        if component.source_url.startswith("https://"):
            sources.setdefault(component.source_url, set()).add(
                f"{component.name} {component.version}"
            )
    lines = [
        "# Roammand macOS Source Code Record",
        "",
        f"- Product: Roammand {metadata.version} (build {metadata.build})",
        f"- Bundle identifier: `{metadata.bundle_identifier}`",
        f"- Copyright holder: {arguments.copyright_holder}",
        f"- Exact project source: {arguments.source_url}",
        f"- Exact Git commit: `{arguments.source_revision}`",
        f"- Payload inventory SHA-256: `{package_digest}`",
        f"- Generated: {created}",
        "",
        "## Source availability",
        "",
        (
            "The exact Roammand source corresponding to this macOS release is "
            f"available at {arguments.source_url}. The immutable commit is "
            f"`{arguments.source_revision}`."
        ),
        "",
        (
            "For MPL-2.0-covered Roammand files, this URL is the source-code "
            "location supplied with the executable distribution. Path-specific "
            "Apache-2.0 components and third-party dependencies retain their own "
            "terms."
        ),
        "",
        "## Toolchain and native source pins",
        "",
        f"- Flutter SDK: `{flutter.version}`",
        f"- Flutter framework revision: `{flutter.framework_revision or 'not reported'}`",
        f"- Flutter engine revision: `{flutter.engine_revision}`",
        f"- Dart SDK: `{flutter.dart_version or 'not reported'}`",
        f"- LiveKit native WebRTC release tag: `{native_tag}`",
        "",
        "## Validated source inputs",
        "",
    ]
    if source_inputs:
        lines.extend(
            f"- `{path}`: `{digest}`"
            for path, digest in sorted(source_inputs.items())
        )
    else:
        lines.append(
            "- Git tree comparison skipped because every fixture input was "
            "supplied explicitly."
        )
    lines.extend(
        [
        "",
        "## Dependency source locations",
        "",
        ]
    )
    for source_url, owners in sorted(sources.items()):
        lines.append(f"- {', '.join(sorted(owners))}: {source_url}")
    lines.extend(
        [
            "",
            "## Reproduction boundary",
            "",
            (
                "The SPDX SBOM and THIRD_PARTY_NOTICES accompanying this file "
                "were generated from the staged macOS payload plus the locked "
                "Cargo, Dart/pub, CocoaPods, Flutter, and native WebRTC inputs. "
                "They do not describe the independently versioned iOS app, "
                "signaling service, or another release."
            ),
        ]
    )
    return "\n".join(lines).rstrip() + "\n"


def stage_and_replace_outputs(
    output_dir: pathlib.Path, contents: dict[str, str]
) -> None:
    if output_dir.exists() and (not output_dir.is_dir() or output_dir.is_symlink()):
        raise fail("compliance output path must be a non-symlink directory")
    output_dir.parent.mkdir(parents=True, exist_ok=True)
    temporary_root = pathlib.Path(
        tempfile.mkdtemp(prefix=".roammand-compliance-", dir=output_dir.parent)
    )
    try:
        for name in OUTPUT_NAMES:
            value = contents[name]
            path = temporary_root / name
            path.write_text(value, encoding="utf-8", newline="\n")
            path.chmod(0o644)
        output_dir.mkdir(parents=True, exist_ok=True)
        for name in OUTPUT_NAMES:
            os.replace(temporary_root / name, output_dir / name)
    finally:
        shutil.rmtree(temporary_root, ignore_errors=True)
