#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""CLI for generating deterministic macOS release compliance assets."""

from __future__ import annotations

import sys

from macos_release_compliance import ComplianceError, main


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ComplianceError as error:
        print(f"macOS release compliance generation failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
