# StaBar

**[English](README_EN.md) | [中文](README.md)**

一款基于 Swift 和 SwiftUI 构建的轻量级原生 macOS 菜单栏系统监控工具。

<p align="center">
  <img src="images/icon.svg" width="128" height="128" alt="StaBar 图标"><br>
  <img src="images/figure.png" width="414" height="295" alt="菜单栏效果"><br>
  <img src="https://img.shields.io/badge/macOS-14%2B-blue">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange">
  <img src="https://img.shields.io/badge/License-MIT-green">
</p>

## 功能特性

- **实时监控** — 一目了然地查看 CPU、GPU、内存、磁盘和网络指标
- **列式布局** — 每个指标独立成列，名称在上、数值在下，完美对齐
- **宽度锁定** — 每列按最坏情况固定宽度，数值跳变时菜单栏图标**不再左右抖动**
- **悬停详情** — 鼠标在菜单栏图标上停留 2 秒（可调 1/2/3 秒）后展开详情面板：一行一个指标，字号更大、数值完整不截断，鼠标移开自动收起
- **完整数值** — 内存与磁盘同时显示百分比与已用/总量（如 `85%  27.3/32 GB`），网速完整显示（如 `↓12.4 ↑3.1 Mbps`）
- **状态配色** — 采用与 Finder 标签一致的 Apple 系统语义色，绿 / 橙 / 红三档直观反映负载
- **单页设置** — 点击菜单栏图标打开设置面板，所有选项一页放下，无需滚动
- **指标开关** — 5 个彩色 chip 一键显示/隐藏 CPU、GPU、内存、磁盘、网络
- **刷新间隔** — 支持 1 秒、2 秒、5 秒、10 秒四种刷新频率
- **网络单位** — 网络速度可选择显示 Kbps 或 Mbps
- **开机自启** — 通过 SMAppService 实现自动启动
- **原生性能** — 纯 Swift/SwiftUI 开发，资源占用极低
- **macOS 设计** — UI 风格与 macOS Tahoe 设计语言一致

## 界面说明

菜单栏里只有紧凑的一行；需要细节时，向下看两个面板：

| 悬停详情面板 | 设置面板 |
| --- | --- |
| ![悬停详情面板](images/hover-panel.png) | ![设置面板](images/settings-panel.png) |

**悬停详情面板**（悬停 2 秒展开）

- 指针悬停在菜单栏图标上 **2 秒**后展开；移出面板或点击别处立即收起
- **不抢占焦点**：展开时不会把当前应用切走
- 每个指标占一行：图标 + 名称 + 百分比 + 细进度条
- 内存/磁盘额外显示 `已用 / 总量`；网络显示 `↓ 下载 ↑ 上传 单位`
- 数值与进度条按负载着色：**绿 < 60%**、**橙 60% ~ 85%**、**红 ≥ 85%**；容量等辅助信息用灰色弱化
- 底部显示系统运行时长与当前刷新间隔

**设置面板**（点击图标展开）

- 紧凑单页布局，所有设置无需滚动即可全部看到
- 顶部 `Metrics` 区用 5 个彩色 chip 开关指标；其余每项一行
- 页脚提供 **Reset**（恢复默认）与 **Quit StaBar**

两个面板宽度一致（290pt），共用同一套材质背景与配色，切换时不会有视觉跳变。

## 系统要求

- **macOS 14 Sonoma** 或更高版本
- 推荐 Apple Silicon (M1/M2/M3)；Intel Mac 待测试

## 安装方法

1. 从 [GitHub Releases](../../releases) 下载最新的 `StaBar.dmg`
2. 打开 DMG 文件，将 **StaBar.app** 拖拽到 **应用程序** 文件夹
3. 从应用程序启动 StaBar

> **注意：** StaBar 未进行代码签名或公证。首次启动时，macOS 可能会阻止运行。请按以下步骤允许：
>
> **系统设置 → 隐私与安全性 → 向下滚动 → 点击"仍要打开"**

## 从源码构建

需要 **Xcode 15+** 及 macOS 14 SDK。

```bash
git clone https://github.com/wpttt/stabar.git
cd stabar

# 构建 Release 版本
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -scheme StaBar \
  -configuration Release \
  SYMROOT=./build build

# 启动应用
open build/Release/StaBar.app
```

运行单元测试：

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  test -scheme StaBar -destination 'platform=macOS'
```

开发时可用一键脚本完成「构建 → 结束旧实例 → 启动新实例」，并校验运行中的确实是最新构建：

```bash
./scripts/relaunch-dev.sh
```

> 若 `xcode-select -p` 指向 CommandLineTools，请先执行
> `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`，
> 或在命令前加 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`。

创建 DMG 安装包：

```bash
./scripts/create-dmg.sh
```

DMG 创建脚本会自动完成：
- 编译应用
- 生成所有尺寸的应用图标
- 将自定义图标应用到 DMG 文件本身
- 设置挂载后 DMG 的卷标图标

## 使用说明

1. **启动应用** — StaBar 仅在菜单栏运行，没有主窗口
2. **查看指标** — 系统指标以独立列的形式显示在菜单栏
3. **悬停详情** — 在菜单栏图标上停留约 2 秒，下方展开详情面板，查看每项指标的完整数值
4. **打开设置** — 点击菜单栏图标打开设置面板
5. **自定义配置** — 开关指标、设置刷新间隔、选择网络单位、开关悬停详情并调整触发延迟
6. **开机自启** — 启用"登录时启动"，让 StaBar 随系统登录自动运行

## 已知限制

1. **GPU 监控** 使用 IOAccelerator 私有 API，部分机型可能取不到数据。此时菜单栏显示 `—`、详情面板显示 `N/A`，不会因整列消失而导致菜单栏宽度变化。
2. **负载配色阈值固定** 为 60% / 85%，暂不支持自定义。
3. **未代码签名** — 用户首次启动时需在系统设置中手动信任应用。
4. **仅支持 macOS 14+** — StaBar 使用了 macOS 14 引入的现代 SwiftUI 特性。

## 许可证

本项目采用 [MIT License](LICENSE) 许可证。

## 致谢

- 灵感来源于 exelban 的 [Stats](https://github.com/exelban/stats) —— 最全面的 macOS 系统监控工具
- rxhanson 的 [Rectangle](https://github.com/rxanson/Rectangle) —— 菜单栏和登录项实现参考
