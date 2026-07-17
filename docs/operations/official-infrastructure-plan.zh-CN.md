<!-- SPDX-License-Identifier: Apache-2.0 -->

# 官方信令与 STUN 实施计划

[English](official-infrastructure-plan.md) · **简体中文**

首期官方服务配置使用无账号信令与公共 STUN：

- 信令：`wss://signal.hcl.life/v1/connect`
- STUN：`stun:stun.hcl.life:3478`
- ICE 策略：`all`
- TURN 中继：不提供

信令属于 WebSocket 流量，可以经过 HTTP 反向代理。STUN 属于 UDP 流量，必须通过直连 DNS 或兼容的四层负载均衡暴露。`https://hcl.life/stun/` 这样的路径不能承载 STUN，普通网站 CDN 也不能替代 UDP 3478。

## 部署边界

公开客户端可以包含官方域名和端口，但不得包含基础设施凭据、私钥、源站地址、SSH 别名、证书路径或运维人员本地路径。STUN 没有密码，也不会中继会话流量。

信令进程在反向代理后只监听私有接口。代理必须覆盖 `X-Real-IP`，服务仅在直连来源属于 `SIGNALING_TRUSTED_PROXY_CIDRS` 时信任该请求头。绝不能把整个互联网配置成可信代理。

## 发布准备

在把该配置描述为普遍可靠之前，必须完成：

1. 验证 WebSocket Upgrade、必需的 Protobuf 子协议、关闭代理缓冲、有界超时和禁止 CDN 缓存。
2. 从独立公网验证 UDP 3478；STUN 本机健康检查不能证明云防火墙规则正确。
3. 监控信令健康状态、进程重启、配对拒绝、证书到期和 STUN 可用性，但不得记录会话载荷或网络映射。
4. 自动化证书续期，并且只部署有明确记录的信令源码版本或经过校验的构建产物。
5. 使用安装版 macOS、Windows Host 和真实 iOS、Android Controller，在相互独立的公网之间测试。
6. ICE 直连失败时展示清晰错误，不能暗示 STUN 可以穿透所有 NAT。

在线状态、配对 rendezvous、限流窗口和活动路由保存在单个信令进程内存中，重启后会清空。首期服务可以使用单实例；横向扩展需要共享路由/状态或消息总线，不能只在负载均衡后启动互不关联的副本。

## 客户端接入

Release 构建包含可恢复的官方配置，并提供 signaling 与 STUN 的运行时自定义配置。选中的配置会传给 GUI 自己管理的 Host Agent。开发者仍可通过明确的环境变量或 Dart definitions，独立运行 signaling、Host Agent 和 Flutter。

Host 修改信令地址后会重启 GUI 管理的 Agent。之前配对的 Controller 会继续保存旧地址，直到经过认证的重新配对为同一 Host 身份替换绑定。STUN 是设备本地 ICE 输入，不会写入配对二维码。

## 后续 TURN 中继

TURN 不进入首期配置，因为它会中继高带宽加密流量，需要滥用控制、allocation 限额、容量监控和短期凭据。后续部署应使用独立的直连 DNS 或四层负载均衡，并且绝不能把长期 TURN 密码写入客户端。
