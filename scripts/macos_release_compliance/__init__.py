# SPDX-License-Identifier: Apache-2.0
"""Generate deterministic compliance assets for a staged macOS release."""

from __future__ import annotations

import argparse
import json
import pathlib

from .collectors import (
    bip39_component,
    brand_component,
    cargo_components,
    dart_components,
    flutter_components,
    material_icons_component,
    merge_components,
    native_webrtc_components,
    pod_components,
)
from .model import (
    ComplianceError,
    Component,
    collect_flutter_metadata,
    collect_shipped_files,
    decode_flutter_notices,
    flutter_assets_root,
    package_metadata,
    parse_arguments,
    required_package_paths,
    validated_source_input_digests,
    validate_release_identity,
)
from .render import (
    build_spdx_document,
    created_timestamp,
    render_notices,
    render_source_record,
    stage_and_replace_outputs,
)


def generate(arguments: argparse.Namespace, repo_root: pathlib.Path) -> str:
    """Generate all compliance documents and return the release version/build."""
    validate_release_identity(arguments)
    package_dir = arguments.package_dir.resolve()
    if not package_dir.is_dir():
        raise ComplianceError("staged macOS package directory does not exist")
    output_dir = arguments.output_dir.resolve()
    metadata = package_metadata(package_dir)
    required_package_paths(package_dir)
    assets_root = flutter_assets_root(package_dir)
    flutter_notices = decode_flutter_notices(assets_root)
    flutter = collect_flutter_metadata(package_dir, repo_root, arguments)
    source_inputs = validated_source_input_digests(repo_root, arguments)
    inventory = collect_shipped_files(package_dir)

    cargo = cargo_components(repo_root, arguments)
    dart = dart_components(repo_root, arguments)
    pods = pod_components(repo_root, arguments)
    native, native_tag = native_webrtc_components(
        package_dir, repo_root, arguments
    )
    bip39 = bip39_component(package_dir, assets_root, repo_root, arguments)
    material_icons = material_icons_component(assets_root, flutter, arguments)
    brand = brand_component(
        assets_root, arguments.copyright_holder, arguments.source_url
    )
    component_inputs: list[Component] = [
        *cargo,
        *dart,
        *pods,
        *native,
        *flutter_components(flutter, flutter_notices),
        bip39,
    ]
    if material_icons is not None:
        component_inputs.append(material_icons)
    if brand is not None:
        component_inputs.append(brand)
    components = merge_components(component_inputs)
    created = created_timestamp()
    spdx = build_spdx_document(
        metadata,
        components,
        inventory,
        source_inputs,
        created,
        arguments,
    )
    contents = {
        "SBOM.spdx.json": json.dumps(
            spdx, indent=2, sort_keys=True, ensure_ascii=False
        )
        + "\n",
        "THIRD_PARTY_NOTICES.md": render_notices(
            metadata,
            components,
            inventory.inventory_sha256,
            created,
            arguments,
        ),
        "SOURCE_CODE.md": render_source_record(
            metadata,
            components,
            flutter,
            native_tag,
            inventory.inventory_sha256,
            source_inputs,
            created,
            arguments,
        ),
    }
    stage_and_replace_outputs(output_dir, contents)
    return f"{metadata.version}+{metadata.build}"


def main() -> int:
    arguments = parse_arguments()
    repo_root = pathlib.Path(__file__).resolve().parent.parent.parent
    release = generate(arguments, repo_root)
    print(f"macOS release compliance assets generated for {release}")
    return 0


__all__ = ["ComplianceError", "generate", "main"]
