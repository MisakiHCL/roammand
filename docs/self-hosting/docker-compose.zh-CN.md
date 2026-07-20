<!-- SPDX-License-Identifier: Apache-2.0 -->

# 使用 Docker Compose 自托管信令与 STUN

[English](docker-compose.md) · **简体中文**

该部署会运行 Roammand 的无账号信令服务，以及仅启用 STUN 的 coturn。信令服务只转发有大小限制的不透明协议消息；STUN 帮助两端发现各自的公网网络映射。两者都不能批准远程控制，也无法读取端到端加密的 WebRTC 媒体。

当前版本不提供 TURN 中继，因此在对称 NAT、企业网络或其他严格网络环境下可能无法建立直连。

## 要求

- Docker Engine 和 Compose v2 插件
- 一个用于信令服务的公网域名
- 该域名受信任的 TLS 完整证书链和未加密私钥
- 可以直接转发到 Docker 主机的公网地址
- 防火墙允许 TCP 8443（WSS）和 UDP 3478（STUN）

STUN 是 UDP 流量，不是 HTTP。`https://example.com/stun/` 这样的路径不能替代 UDP 3478，普通网站 CDN 也不能代理它。

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

示例配置还会把信令服务限制为最多 1,024 个并发 WebSocket 连接、每个来源 IP
64 个连接，以及每台 Host 最多 4 个活动配对 rendezvous。可根据机器内存、NAT
后的预期设备数量和流量，在 `.env` 中调整
`SIGNALING_MAX_CONNECTIONS`（1–65,536）、
`SIGNALING_MAX_CONNECTIONS_PER_IP`（1–65,536）和
`SIGNALING_MAX_RENDEZVOUS_PER_HOST`（1–64）；服务启动时会拒绝无效或无上限值。

这些运维配置之外，出站载荷副本还有不可调大的硬预算：进程全局 64 MiB、同一来源
IP 的所有连接合计 4 MiB、每个连接 526,336 字节（两个最大尺寸的帧）。每个连接
64 条的队列上限仍然有效；排队中和正在写入套接字的字节都会计入所有适用预算，
投递失败或连接关闭时会释放全部预留。

## 校验并启动

```bash
docker compose --env-file .env -f compose.yaml config
docker compose --env-file .env -f compose.yaml up -d --build
docker compose --env-file .env -f compose.yaml ps
```

两个容器都使用非 root 用户、只读根文件系统、移除 Linux capabilities、启用 `no-new-privileges`，并配置有界日志和健康检查。Coturn 使用 `stun-only`，只发布 UDP 3478，不包含用户数据库、relay 端口范围、TLS 监听或 TURN 凭据。

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

如果在 Nginx 或其他反向代理终止 TLS，需要转发 WebSocket Upgrade、保留 `roammand-signaling.v1.protobuf` 子协议、关闭响应缓冲，并把 `X-Real-IP` 设置成代理观察到的客户端地址。`SIGNALING_TRUSTED_PROXY_CIDRS` 只能配置实际代理网络，绝不能信任整个互联网传入的转发头。

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

## 运维

替换证书和私钥后，只重建信令容器即可：

```bash
docker compose --env-file .env -f compose.yaml up -d --force-recreate signaling
```

使用 `docker compose --env-file .env -f compose.yaml down` 停止部署。信令在线状态、配对 rendezvous 和限流窗口只保存在内存中，重启后会清空；设备本地身份和授权不会受影响。
