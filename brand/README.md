<!-- SPDX-License-Identifier: Apache-2.0 -->

<p align="center">
  <img src="roammand-app-icon.svg" width="112" alt="Roammand logo">
</p>

# Roammand brand design guidelines

**English** · [简体中文](README.zh-CN.md)

**Positioning:** private, account-free mobile control for your own computers.

**Tagline:** Leave the desk. Keep work moving.

**中文：**离开桌面，工作仍在继续。

Roammand extends the personal workspace from desk to mobile. It keeps identity and authority with the owner while making active work reachable from anywhere. Remote control is the foundation for a more continuous, agentic way of working.

## Name and voice

“Roammand” combines *roam* and *command*. Keep the spelling and capitalization exactly `Roammand`; do not split or translate the product name.

- **Direct:** lead with the action, device, or state.
- **Composed:** use calm, confident language without exaggeration.
- **Personal:** speak about the user's computer, work, and authority.
- **Exact:** name the Controller, recovery window, permission, and data boundary when they matter.

## Night Aurora color system

Night ink forms the workspace, aurora indigo anchors the identity, and signal cyan marks connection and activity. Light inverse surfaces provide crisp contrast for primary actions and the logo.

| Role | Value | Use |
| --- | --- | --- |
| Canvas | `#090B1F` | App background and icon field |
| Deep surface | `#11142D` | Navigation and default cards |
| Elevated surface | `#191E41` | Dialogs and emphasized panels |
| Aurora indigo | `#7E7BFF` | Brand focus and selected state |
| Aurora soft | `#A9A7FF` | Secondary brand text/icons |
| Signal cyan | `#32C9F3` | Live connection and progress |
| Inverse surface | `#F3F2FF` | Primary action and logo contrast |
| Primary text | `#F3F2FF` | Main copy on dark surfaces |
| Secondary text | `#B8BBD6` | Supporting copy |
| Outline | `#34395F` | Dividers and quiet borders |
| Online | `#59D8B5` | Ready and connected |
| Attention | `#F6C66B` | Permission or action required |
| Emergency | `#FF728B` | Failure, revoke, or stop control |

Do not use the indigo/cyan gradient as a semantic status. Green means ready, amber means attention, and red is reserved for destructive or stopped states. Body text and essential controls must retain WCAG AA contrast.

## Typography and layout

Roammand uses each platform's system sans serif for native rendering and consistent legibility. Headings use 600–700 weight with slightly tightened tracking; body text uses a relaxed `1.45` line height.

- Use a 4-point spacing grid; the usual steps are 4, 8, 12, 16, 20, 24, 32, and 48.
- Keep primary touch targets at least 48 points and all icon-only controls at least 44 points.
- Use 20-point radii for cards/dialogs, 14-point radii for controls/fields, and full pills only for short status labels.
- Prefer quiet 1-point outlines to decorative shadows. Elevation should explain hierarchy, not decorate every surface.
- Keep reading regions bounded on wide desktop layouts and allow navigation to switch from rail to bottom bar in narrow windows.
- Respect safe areas, landscape, keyboard insets, text scaling, and reduced-motion settings.

Motion should confirm a state change: roughly 160 ms for local feedback and 240 ms for layout transitions. Avoid looping decoration, parallax on remote content, or animation that delays Stop/Emergency stop.

## Logo system

The mark joins a desktop workspace and mobile Controller with a single command path. Its double-frame silhouette and control point remain recognizable at small sizes.

| Asset | Role |
| --- | --- |
| `roammand-app-icon.svg` | Opaque source for platform app icons |
| `roammand-mark.svg` | Primary mark on a Night Aurora surface |
| `roammand-mark-monochrome.svg` | One-color and inverse applications |
| `roammand-tray-template.svg` | Small menu bar/system tray source |
| `roammand-app-icon-1024.png` | Reviewable 1024 px raster master |

Keep clear space around the mark at least equal to the diameter of its control ring. Preserve its orientation, geometry, and color relationships; use the monochrome tray asset according to each platform's template-icon rules.

On macOS, regenerate the committed PNG and ICO derivatives with:

```bash
./scripts/render_brand_assets_macos.sh
```

The deterministic renderer requires Quick Look and Python Pillow. Routine application builds consume committed derivatives and do not require either tool.

## Product asset checklist

Before a public release, verify the app icon on real Home Screens, Dock/taskbar, Spotlight/Start, installer surfaces, and 16 px tray/menu bar contexts. Store screenshots and marketing artwork must use product UI that matches the shipped build, preserve safe areas, and avoid displaying real device identities, endpoints, pairing codes, or diagnostics.
