<!-- SPDX-License-Identifier: Apache-2.0 -->

# 使用 Docker Compose 自托管信令与 STUN

[English](docker-compose.md) · **简体中文**

该部署会运行 Roammand 的无账号信令服务，以及仅启用 STUN 的 coturn。信令服务会转发有大小限制的协议 envelope，但当前实现不解析内层格式；STUN 帮助两端发现各自的公网网络映射。两者都不能批准远程控制，也无法读取端到端加密的 WebRTC 媒体。“不透明”是对当前 signaling 实现的描述，不表示这些字节对运维方保密。

该配置不提供 TURN 中继，因此在对称 NAT、企业网络或其他严格网络环境下可能无法
建立直连。

## 要求

- Docker Engine 和 Compose v2 插件
- 一个用于信令服务的公网域名
- 该域名受信任的 TLS 完整证书链和未加密私钥
- 可以直接转发到 Docker 主机的公网地址
- 防火墙允许 TCP 8443（WSS）和 UDP 3478（STUN）

STUN 是 UDP 流量，不是 HTTP。`https://example.com/stun/` 这样的路径不能替代 UDP 3478，普通网站 CDN 也不能代理它。

## 部署与隐私边界

参考拓扑只运行一个 signaling 实例，并在该容器内终止 TLS。在线状态、配对
rendezvous、限流窗口和路由都保存在进程内存中；不要把彼此独立的多个实例直接放在
负载均衡器后。多实例部署需要共享路由/状态，而本仓库尚未提供这一能力。

服务不持有设备授权或长期密钥，但也不是匿名基础设施。WSS 会在 signaling
终止，因此该进程与运维方可以访问所转发的内层 envelope 字节，包括公开身份证明和
WebRTC 协商元数据，也可看到 TCP 来源地址、已注册路由标识符、时间和大小。
当前实现不解析、不持久化、通常也不记录这些内层正文。STUN 会看到需要返回
公网映射的地址/端口。运维方必须限制对运行时、代理日志、遥测和基础设施流量日志的访问。

## 准备配置

在仓库根目录执行：

```bash
cd infra/compose
cp .env.example .env
mkdir -m 700 secrets
```

把信令完整证书链复制到 `secrets/tls-cert.pem`，私钥复制到 `secrets/tls-key.pem`。让信令容器使用的数字组可以读取，但不要公开私钥：

```bash
sudo chown "$(id -un)":65532 secrets/tls-cert.pem secrets/tls-key.pem
chmod 640 secrets/tls-cert.pem secrets/tls-key.pem
```

如果文件放在其他位置，请修改 `.env`。不要提交 `.env`、证书、私钥、公网地址或运维人员本地路径。

Dockerfile 专用 ignore 文件（以及与它一致的根级 fallback）使用 allowlist：只有
`gen/go` 和 `services/signaling` 会进入信令镜像的构建上下文。因此 Compose
secrets、环境文件、仓库元数据和常见本地构建产物不会发送给 Docker daemon 或已配置的
远程 builder。修改 Dockerfile 时必须同步保留这两层边界，也不要把凭据放入允许进入
上下文的源码目录。

示例配置还会把信令服务限制为最多 1,024 个并发 WebSocket 连接、每个来源 IP
64 个连接、全局 4,096 个活动配对 rendezvous，以及每台 Host 最多 4 个活动
rendezvous。可根据机器内存、NAT 后的预期设备数量和流量，在 `.env` 中调整
`SIGNALING_MAX_CONNECTIONS`（1–65,536）、
`SIGNALING_MAX_CONNECTIONS_PER_IP`（1–65,536）、
`SIGNALING_MAX_RENDEZVOUS`（1–65,536）和
`SIGNALING_MAX_RENDEZVOUS_PER_HOST`（1–64）；服务启动时会拒绝无效或无上限值。
`SIGNALING_SHUTDOWN_TIMEOUT` 默认为 10 秒、最多一分钟，并保持短于 Compose
停止宽限期。

这些运维配置之外，出站载荷副本还有不可调大的硬预算：进程全局 64 MiB、同一来源
IP 的所有连接合计 4 MiB、每个连接 526,336 字节（两个最大尺寸的帧）。每个连接
64 条的队列上限仍然有效；排队中和正在写入套接字的字节都会计入所有适用预算，
投递失败或连接关闭时会释放全部预留。

入站流量使用固定的 1 秒窗口，同时限制帧数与字节数：每个连接 256 帧 /
32 MiB，每个来源 IP 4,096 帧 / 128 MiB，进程全局 32,768 帧 / 512 MiB。
应用消息和收到的 WebSocket ping/pong 帧都会计入。超过任一上限，或来自新来源且
65,536 条流量 IP 映射已满时，服务会以状态码 1013（`Try Again Later`）关闭
WebSocket。这些是固定安全上限，不是环境变量调优项。

配对创建与加入请求共享每个来源 IP 每 60 秒 30 次的独立预算；加入请求还受
每个 rendezvous ID 或归一化配对码每 60 秒 5 次的限制。配对限流器最多保留
65,536 个来源 IP 窗口与 262,144 个 lookup 窗口；任一相关映射已满时，
新 key 会被拒绝（fail closed），并返回 `PAIRING_RATE_LIMITED` 与有界重试延迟。

只完成部分传输的二进制消息使用另一组固定在途内存预算。WebSocket 消息 header
到达后，每个活动读取会预留 263,169 字节，并同时受来源 IP 8 MiB、进程全局
64 MiB 预算约束；消息正文必须在 10 秒内完成。成功、超时、拒绝和连接关闭都会
释放预留。这些上限可防止慢速分片消息绕过已完成帧的速率窗口，也不是运维调优项。

## 校验并启动

```bash
docker compose --env-file .env -f compose.yaml config
docker compose --env-file .env -f compose.yaml up -d --build
docker compose --env-file .env -f compose.yaml ps
```

两个容器都使用非 root 用户、只读根文件系统、移除 Linux capabilities、启用
`no-new-privileges`，并配置有界日志和健康检查；signaling 还配置了进程数限制。
coturn 镜像同时固定版本与 digest。Coturn 使用 `stun-only`，只发布 UDP 3478，
不包含用户数据库、relay 端口范围、TLS 监听或 TURN 凭据。

最终端点为：

- 信令：`wss://signal.example.com:8443/v1/connect`
- STUN：`stun:stun.example.com:3478`

两个域名可以解析到同一台主机。当前配置使用标准 UDP STUN，而不是 STUNS/TLS，所以 STUN 域名不需要 HTTPS 证书。

在每一端 Roammand 中打开“网络服务”，选择“自定义服务”，填写上述两个端点。独立运行 Host Agent 的开发者也可以不经过 GUI：

```bash
ROAMMAND_SIGNALING_ENDPOINT='wss://signal.example.com:8443/v1/connect' \
ROAMMAND_STUN_URLS='stun:stun.example.com:3478' \
cargo run -p roammand-host-agent --features native-webrtc -- serve
```

随附 Compose 文件会在 signaling 进程内终止 TLS。如果自定义部署改为在 Nginx
或其他反向代理终止 TLS，必须同时移除两个 signaling TLS 变量及其 secret
挂载/定义，只把明文源站绑定到私有容器/主机网络，并且绝不能公开该源站端口。代理
需要转发 WebSocket Upgrade、
保留 `roammand-signaling.v1.protobuf` 子协议、关闭响应缓冲，并用代理实际观察到的
客户端地址覆盖 `X-Real-IP`。`SIGNALING_TRUSTED_PROXY_CIDRS` 只能配置直连代理
网络；服务会拒绝覆盖完整 IPv4 或 IPv6 地址族的 CIDR。绝不能信任整个互联网传入
的转发头。

## 从另一网络验证

检查信令状态时不要输出私密材料：

```bash
curl --fail https://signal.example.com:8443/healthz
docker compose --env-file .env -f compose.yaml logs signaling
```

在 Docker 主机网络之外的机器使用 `turnutils_stunclient`：

```bash
turnutils_stunclient -p 3478 stun.example.com
```

容器本地健康检查成功，并不能证明云防火墙已经允许公网 UDP 3478。公开端点前，必须使用安装版 Host 和 Controller 在两个相互独立的网络之间完成测试。

`/healthz` 只能证明 HTTP 进程正在服务。当前 Host 与配对链路每 15 秒发送一次
heartbeat，Controller 会话链路使用 20 秒周期。每条链路同时只允许一个 heartbeat，
要求确认严格关联到该请求；下一周期仍未确认时，会进入有界关闭或认证恢复路径。
客户端的连接、请求/写入和关闭工作也有边界。监控时应观察真实客户端成功率和有界的
恢复/错误计数，不要把标识符或载荷加入日志。

## 运维

替换证书和私钥后，只重建信令容器即可：

```bash
docker compose --env-file .env -f compose.yaml up -d --force-recreate signaling
```

使用 `docker compose --env-file .env -f compose.yaml down` 停止部署。信令在线状态、配对 rendezvous 和限流窗口只保存在内存中，重启后会清空；设备本地身份和授权不会受影响。

服务端没有需要备份的信任数据库。只需保护和备份运维方自己的 Compose 配置与 TLS
材料，并使用秘密管理系统而不是仓库保存。升级时应部署经过审阅的源码修订、重新构建
signaling 镜像、验证两项健康检查，并完成一次真实跨网络会话。重建 signaling
进程时，已连接客户端和正在进行的配对 rendezvous 会受到中断。
