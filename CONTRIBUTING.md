# Contributing

Roammand welcomes focused, test-backed contributions that preserve its privacy and trust boundaries.

## Before opening a change

1. Check the issue tracker for an existing design or discussion.
2. Keep protocol changes backward-compatible unless a version change is explicitly approved.
3. Do not commit credentials, private keys, pairing material, SDP, ICE candidates, typed text, pointer coordinates, or private diagnostic bundles.
4. Run `make doctor`, `make format-check`, and `make test`.

## Code expectations

- Add or update tests before changing behavior.
- Keep user-visible text in Flutter localization resources.
- Validate all external input and enforce length limits.
- Give every connection, media track, timer, capture task, and input state an explicit cleanup path.
- Add the correct SPDX identifier to new source files.
