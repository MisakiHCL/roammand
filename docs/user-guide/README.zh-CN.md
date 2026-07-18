<!-- SPDX-License-Identifier: Apache-2.0 -->

# Roammand 用户指南

[English](README.md) · **简体中文**

> Roammand 正在准备首次公开发布。macOS 安装包已经具备分发条件，但公众下载
> 地址尚未发布；iPhone 和 iPad App 也尚未在 App Store 上线。

## 开始之前

- 当前 macOS 版本要求 macOS 14.4 或更高版本。
- Mac 必须授予 Roammand“屏幕录制”和“辅助功能”权限，之后才能接受连接。
- 当前版本只尝试 ICE 直连，没有 TURN 中继兜底。某些严格或对称的网络组合可能
  无法连接。

## 安装并授权 Mac

1. 公众下载地址发布后，从官方渠道下载经过签名和公证的 `.pkg`。
2. 打开安装包，并批准管理员提示，以安装 App 和所需的 Host 组件。
3. 启动 Roammand，打开“**此电脑**”。
4. 分别点击两项“**去设置**”，在系统设置中授予“屏幕录制”和“辅助功能”权限。
5. 返回 Roammand。只有两项权限都就绪后，配对和传入连接才会变为可用。

权限请求只会由这些本机设置操作发起。远程连接不会代替 Mac 用户请求权限。

## 安装 iPhone 或 iPad App

1.0.0 版本尚未公开上线。[App Store 页面](https://apps.apple.com/app/id6792014935)
用于即将发布的正式版本，TestFlight 仍仅供受邀测试者使用。

安装后打开 App 并设置设备名称。Mac 批准 Controller 时会显示这个名称。

## 配对设备

1. 在 Mac 上打开“**此电脑**”，创建手机二维码邀请。
2. 使用 iPhone 或 iPad 扫描二维码。
3. 核对两台设备显示的四个验证词。
4. 在 Mac 上批准名称正确的 Controller。
5. 在“**我的电脑**”中选择这台 Mac，然后点击“**连接**”。

配对授权是单向的。如果要交换 Host 和 Controller 的方向，需要重新配对并单独
批准。

## 连接失败时

- 如果 Mac 显示授权未完成，请先完成两项权限设置，再重新连接。
- 确认 Mac 上的 Roammand 正在运行，并且 Host 显示为可用。
- 尝试让其中一台设备切换网络。没有 TURN 时，即使两台设备都能连接 signaling，
  严格网络仍可能阻止直连。
- 如果出现非预期的 Controller，请立即在 Mac 本机停止会话。

## 从 macOS 卸载

打开“**设置 → 高级 → 卸载 Roammand**”。受保护卸载器会移除 App、Host 组件、
launchd 配置、运行文件、日志、设备身份、配对授权、已保存 Host、偏好设置、缓存，
以及仅属于 Roammand 的屏幕录制和辅助功能授权。重新安装后会生成新的设备身份，
并需要重新配对。

技术安全边界见[安全指南](../security/README.zh-CN.md)。开发者和源码构建者请使用
[构建指南](../BUILDING.zh-CN.md)。
