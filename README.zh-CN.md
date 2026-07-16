<!-- SPDX-License-Identifier: Apache-2.0 -->

<p align="center">
  <img src="brand/roammand-app-icon.svg" width="112" alt="Roammand 标志">
</p>

<h1 align="center">Roammand</h1>

<p align="center"><strong>离开桌面，工作仍在继续。</strong></p>
<p align="center">无账号、隐私优先，安全控制你自己的电脑。</p>

[English](README.md) · **简体中文**

Roammand 把手机、平板或另一台电脑变成可信控制界面，让你随时操作承载工作的 Windows 和 macOS 电脑。设备之间直接配对，无需账号，以后可以直接重连。

从移动端继续桌面工作、掌握长时间任务，让个人计算环境始终触手可及。

## 你可以做什么

- 使用二维码配对手机，或通过一次性代码和四词验证配对另一台电脑。
- 保存可信电脑，以后无需重新配对即可连接。
- 从 iOS、Android、Windows 或 macOS 控制 Windows 和 macOS。
- 在移动端使用触控手势、文本、修饰键和特殊键。
- 在短暂中断后通过有界、经过认证的流程恢复连接。
- 在 Host 上查看连接者、本机停止控制，并撤销任意 Controller。
- 导出隐私安全的诊断信息，并自托管 signaling 与 TURN 服务。

## 如何使用

1. 在 Host 的“此电脑”中创建手机二维码邀请或桌面配对码。
2. 扫描或输入邀请，核对四个验证词，并在 Host 旁批准显示名称正确的 Controller。
3. 电脑会出现在“我的电脑”中；以后选择“连接”即可继续远程工作。

授权始终是单向的：Controller 只能访问批准它的 Host。如果需要反向控制，必须重新配对并单独批准。

## 支持的平台角色

| 平台 | Host | Controller |
| --- | --- | --- |
| macOS | 支持 | 支持 |
| Windows | 支持 | 支持 |
| iOS / iPadOS | — | 支持 |
| Android | — | 支持 |

## 从源码开始

安装固定版本工具链和工作区依赖：

```bash
make bootstrap
make app-check
```

这些工作流会隐藏成功时的工具日志，最后只打印一行 `[PASS]` 结论；失败时会显示简短的错误末尾。需要查看完整过程时可添加 `VERBOSE=1`，例如 `make app-check VERBOSE=1`。

启动 signaling 服务：

```bash
cd services/signaling
go run ./cmd/signaling
```

在仓库根目录启动带原生 WebRTC 的 Host Agent：

```bash
ROAMMAND_SIGNALING_ENDPOINT='ws://127.0.0.1:8080/v1/connect' \
cargo run -p roammand-host-agent --features native-webrtc -- serve
```

使用相同地址运行 macOS App：

```bash
make app-run-macos \
  FLUTTER_ARGS='--dart-define=ROAMMAND_SIGNALING_ENDPOINT=ws://127.0.0.1:8080/v1/connect'
```

Release 构建和常规跨设备网络必须使用所有设备都信任证书的 WSS。源码 Debug 构建可显式允许私有局域网 IP 上的明文 `ws://`，方便实体设备开发；受保护的启动命令、平台依赖、TURN 配置、Release 构建和 Host 打包见[从源码构建 Roammand](docs/BUILDING.zh-CN.md)。

## 安全设计

- 不需要云账号。
- 长期私钥和设备授权保存在设备本地。
- 只有 Host 本机批准后才会创建永久授权。
- signaling 只转发有大小限制的不透明消息，不能批准控制。
- Host 会持续显示控制状态，并提供本机“停止”和“紧急停止”。
- 会话恢复或图形会话切换期间会释放并阻止输入。
- 诊断信息不包含设备身份、网络地址、SDP/ICE、输入、屏幕、凭据或原始载荷。

准确的安全边界见[配对模型](docs/architecture/account-free-pairing-v1.md)、[特权会话桥接](docs/architecture/privileged-session-bridge-v1.md)、[威胁模型](docs/security/privileged-helper-threat-model.md)和[诊断策略](docs/security/privacy-safe-diagnostics.md)。

## 自托管

Roammand 提供固定版本的 signaling 与 coturn Docker Compose 部署，以非 root 服务、文件 secrets、健康检查、显式 relay 端口和有界日志运行。参见 [Docker Compose 自托管](docs/self-hosting/docker-compose.md)。

## 项目文档

- [构建、运行、打包和验证](docs/BUILDING.zh-CN.md)
- [品牌设计规范](brand/README.zh-CN.md)
- [架构](docs/architecture/README.zh-CN.md)
- [安全](docs/security/README.zh-CN.md)
- [运维](docs/operations/README.zh-CN.md)
- [验证](docs/testing/README.zh-CN.md)

## 许可证

Roammand 按仓库路径使用不同的开源许可证。完整条款见[许可证与第三方声明](LICENSES.md)。
