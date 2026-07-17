<!-- SPDX-License-Identifier: Apache-2.0 -->

# 官方信令与中继服务实施计划

[English](official-infrastructure-plan.md) · **简体中文**

状态：**暂缓实施**。当前先完善客户端生命周期。本文件不代表服务器已经部署，也不记录服务器地址、SSH 配置、证书路径或任何凭据。

## 预定公共端点

- 信令：`wss://signal.hcl.life/v1/connect`
- TURN UDP：`turn:turn.hcl.life:3478?transport=udp`
- TURN TCP：`turn:turn.hcl.life:3478?transport=tcp`
- TURN TLS/TCP：`turns:turn.hcl.life:5349?transport=tcp`
- 短期 TURN 凭据：HTTPS 控制面接口，优先放在 `https://signal.hcl.life/v1/` 下。

信令属于 WebSocket 流量，可以由 HTTP 反向代理转发。TURN 不是 HTTP，必须通过直连 DNS 或兼容的四层负载均衡暴露。`https://hcl.life/turn/` 这样的路径可以用于签发临时凭据，但不能承载 TURN 中继流量。

## 部署边界

官方客户端可以包含公开服务域名，但不得包含长期 TURN 密码、基础设施凭据、私钥、服务器地址或运维人员的本地路径。

首次受控预览可以让信令与 coturn 同机运行；正式公共服务应当隔离 TURN，因为 TURN 必须被公网直接访问，并承载高带宽中继流量。如果 TURN 与主站共用源站地址，即使主站使用 CDN，TURN 的 DNS 记录仍会让该源站地址可被发现。

## 对外使用前必须完成

1. 信令放到 Nginx、CDN 或负载均衡之后前，增加可信代理配置，确保 IP 限流使用真实客户端地址且不无条件信任伪造的转发头。
2. 用短期 HMAC 凭据替换固定 coturn 用户，认证共享密钥只保存在服务端。
3. 按公共预览规模配置 allocation、带宽、端口范围和滥用限制，不能直接沿用当前面向个人部署的 Compose 容量。
4. 配置 WebSocket Upgrade、禁用缓存、长连接超时、证书、健康检查、防火墙规则和密钥轮换。
5. 在相互独立的网络上测试直连 ICE 与强制 relay，再把官方默认端点写入 Release 构建。
6. 监控信令连接数、TURN allocation、带宽、认证失败、容器重启和证书到期，同时不得记录私密会话载荷。

当前信令的在线状态与配对 rendezvous 保存在单进程内存中。单实例足以支持带自动重连的预览版本；横向扩展需要共享路由/状态或消息总线，不能仅靠在负载均衡后启动多个副本。

## 部署完成后的客户端接入

Release 构建会把公开信令端点和 TURN 凭据接口同时提供给 GUI 及其管理的 Host Agent。开发构建继续保留环境变量覆盖，并允许开发者分别运行信令、coturn、Host Agent 和 Flutter。

只有在安装版 macOS、Windows Host 以及真实 iOS、Android Controller 均通过跨公网测试后，才能把本计划标记为完成。
