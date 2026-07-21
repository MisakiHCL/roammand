<!-- SPDX-License-Identifier: Apache-2.0 -->

# 运维指南

[English](README.md) · **简体中文**

运维检查用于补充自动化测试，覆盖必须在真实设备和受保护操作系统桌面上观察的产品行为。

- [发行验收](final-product-acceptance.md) — 在真实 macOS、Windows、iOS 和 Android 上检查安装、配对、控制、恢复、权限、本机停止、紧急停止和清理。
- [官方 signaling 与 STUN 配置](official-infrastructure-plan.zh-CN.md) — 记录公开端点、元数据与部署边界、就绪检查，以及明确不提供 TURN 中继的限制。

执行清单前，请先使用[从源码构建 Roammand](../BUILDING.zh-CN.md)中的打包与安装命令。自托管 signaling 与 STUN 部署见 [Docker Compose 自托管](../self-hosting/docker-compose.zh-CN.md)。
