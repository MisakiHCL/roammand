<!-- SPDX-License-Identifier: Apache-2.0 -->

# 验证指南

[English](README.md) · **简体中文**

Roammand 将确定性自动化门禁与必须依赖真实设备、网络、权限或受保护操作系统桌面的验收证据分开管理。

- [桌面会话](desktop-session.md) — 认证 WebRTC、采集、输入、ICE/TURN 和生命周期。
- [配对](pairing.md) — 二维码与一次性代码、四词验证、本机批准、持久化和撤销。
- [移动 Controller](mobile-controller.md) — iOS 与 Android 控制 Windows 和 macOS Host 的实体设备覆盖。
- [可靠性与隐私](reliability-and-privacy.md) — 恢复、诊断、不可信输入、自托管和资源观测。
- [平台验收](platform-acceptance.md) — 已安装 Host、受保护桌面、打包和跨平台发行证据。

使用 `make test-product` 运行完整确定性门禁；目标系统签字验收见[人工验收清单](../operations/final-product-acceptance.md)。
