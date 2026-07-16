<!-- SPDX-License-Identifier: Apache-2.0 -->

# 安全指南

[English](README.md) · **简体中文**

Roammand 将长期身份和授权保留在用户设备上。以下文档说明敏感资产、特权运行边界、失败处理，以及用户导出的诊断报告可以包含哪些数据。

- [特权 Helper 威胁模型](privileged-helper-threat-model.md) — 受保护资产、可信角色、本地 peer 认证、路由迁移、打包和失败关闭行为。
- [隐私安全诊断](privacy-safe-diagnostics.md) — 类型化诊断白名单、明确排除的数据、保留限制和由用户控制的本地导出。

端到端信任和授权流程见[架构指南](../architecture/README.zh-CN.md)。报告安全漏洞请遵循 [SECURITY.md](../../SECURITY.md)。
