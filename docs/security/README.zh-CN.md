<!-- SPDX-License-Identifier: Apache-2.0 -->

# 安全指南

[English](README.md) · **简体中文**

Roammand 将长期身份和授权保留在用户设备上。允许远程控制的权威是 Host 本机授权
注册表，而不是云账号、signaling 连接、二维码或 STUN/TURN 服务。

## 安全目标

- 只有 Host 已为准确的 Controller 公共身份保存单向授权后，该 Controller 才能
  发起会话。
- 配对、会话 Offer/Answer 与恢复流程把身份、nonce、有效期、权限、SDP 摘要和
  DTLS 指纹绑定到经过签名的规范 transcript。
- 画面与输入通过两端之间经过认证的 WebRTC 保护传输。signaling 只路由有界协商
  消息，不能生成设备签名或授权。
- 桌面私钥与授权保存在受保护的本地存储中。特权 Broker/Helper 只获得范围受限、
  有时效的权限，不持有 Host 长期秘密。
- 权限丢失、畸形输入、重放、队列压力、路由迁移、租约过期或会话失败都会释放
  已按住的输入，并以失败关闭方式结束。

## 数据与元数据可见性

“无需账号”不等于匿名，也不代表不存在网络元数据。运维方和用户应了解每个参与者
必然会处理什么。

| 参与者 | 可以观察的数据 | 设计上不会接收的数据 |
| --- | --- | --- |
| Controller 与 Host | 会话所需的远程画面/输入、经过认证的 peer 身份、与对端交换的 ICE 数据 | 对端长期私钥 |
| signaling 服务 | 连接期间的 TCP 来源地址、注册/路由设备 ID、rendezvous 状态、时间、大小、有界外层路由字段，以及它所转发的内层 envelope 字节 | 长期私钥、Host 本机保存的授权库，或解密后的 WebRTC 画面/输入内容 |
| STUN 服务 | 返回公网映射所需的来源地址/端口与请求时间 | 屏幕媒体、输入、设备授权或 TURN 中继流量 |
| 可选的开发者自建 TURN | 对端地址、时间、流量大小和所中继的加密 WebRTC 数据包 | 解密后的 DTLS-SRTP/SCTP 内容或授权能力 |
| 导出的诊断 | 预览中列出的类型化聚合白名单 | 设备身份、地址、SDP/ICE、凭据、输入、像素、原始载荷或堆栈 |

当前 signaling 实现把内层 envelope 当作不透明字节：不解析其格式、不记录正文、
不持久化。这是数据最小化措施，而不是对运维方的端到端保密，因为 WSS 会在
signaling 服务终止。被修改或入侵的进程可以解析或留存所转发的公开身份证明与
WebRTC 协商元数据。已签名的身份、SDP 和指纹绑定可防止 signaling 批准 Controller
或悄然替换协商内容，但不会隐藏所有协商字节。相关服务仍可观察端点、时间、
大小和流量元数据。

## 信任假设与限制

- 操作系统、Host 所有者和已批准的 Controller 设备属于信任边界。终端被入侵后，
  攻击者可以读取或生成该终端本来就有权处理的数据。
- 本地 IPC 会隔离其他操作系统用户以及过期或被替换的端点，但无法抵御已使用同一
  用户完整权限运行的任意代码，也不能抵御管理员/root 权限被攻破。
- 二维码配对时 Host 所有者必须核对 Controller 名称；桌面配对码流程必须核对全部
  四个英文验证词。误批准会创建真实授权，直至 Host 本机撤销。
- 本设计不承诺匿名、抵御全局流量分析、signaling 可用性或穿透全部 NAT。公开配置
  没有 TURN 兜底，signaling 路由状态由单实例保存在内存中。
- Flutter 当前的 WebSocket API 会先把完整消息交给 Controller，之后才能执行
  263,168 字节的应用帧检查。官方服务会限制转发消息，但不可信的自定义 signaling
  端点仍可能让客户端产生更大的瞬时分配；要在分配前执行该上限，需要有界的原生或
  流式 transport。
- Roammand 不绕过平台控制。macOS TCC/FileVault 与 Windows UAC、完整性级别、
  Winlogon 和 SendSAS 策略仍具有最终决定权。
- Roammand 不提供自动安全更新。运维方和用户需要自行跟踪最新发行版或经过审阅的
  源码修订。

## 安全文档

- [特权 Helper 威胁模型](privileged-helper-threat-model.md) — 受保护资产、可信角色、本地 peer 认证、路由迁移、打包和失败关闭行为。
- [隐私安全诊断](privacy-safe-diagnostics.md) — 类型化诊断白名单、明确排除的数据、保留限制和由用户控制的本地导出。
- [无账号配对 V1](../architecture/account-free-pairing-v1.md) — 邀请类型、认证交换、本机批准、持久化和重放处理。
- [桌面身份与本地 IPC V1](../architecture/desktop-identity-ipc-v1.md) — 密钥存储、同用户边界、认证 framing 与清理。
- [桌面 WebRTC V1](../architecture/desktop-webrtc-v1.md) — 会话认证、媒体/输入保护、ICE、权限和生命周期。
- [认证恢复 V1](../architecture/reconnect-v1.md) — 有界恢复、全新认证和输入失败关闭行为。

完整组件链路见[架构指南](../architecture/README.zh-CN.md)。如需避免公开披露漏洞，
请遵循 [SECURITY.md](../../SECURITY.md)。
