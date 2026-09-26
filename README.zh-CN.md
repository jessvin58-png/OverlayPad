# OverlayPad

[English](README.md) | [简体中文](README.zh-CN.md)

可自定义虚拟手柄，为触屏上的游戏操作而设计
适用于 UNDERTALE / DELTARUNE 以及任意支持手柄的游戏/应用（支持四个方向键）

注入的是**原生GameController输入**

## 功能

- 长按悬浮球隐藏/恢复控件
- 摇杆与按键可拖动、缩放、改色、改形状、改映射
- 支持组合键与自动连点
- 预设可导出/导入，分享 `.json` 即可复现布局
- 中英双语，跟随系统或手动切换
- 编译时可通过 `make DEBUG=1` 开启debug控制台

## 要求

- 目标游戏或应用需支持接入手柄（可识别GameController输入），否则虚拟手柄无法生效
- iOS 15+
- 在 visionOS 上可能需要额外的权限声明

## 使用

将 `OverlayPad.dylib` 注入到目标app中，以下方式均可：

- 注入 IPA 后重新签名/巨魔（TrollStore）安装
- LiveContainer 等侧载环境

## 许可

本项目采用 [LGPL-3.0](LICENSE)。

欢迎fork、二改、打包分发
联系方式：locationovo@outlook.com