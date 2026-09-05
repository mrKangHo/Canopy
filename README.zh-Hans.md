<p align="center">
  <a href="README.md">English</a> · <a href="README.ko.md">한국어</a> · <a href="README.ja.md">日本語</a> · <b>简体中文</b>
</p>

<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Canopy 应用图标">
</p>

# Canopy

一款原生 macOS 菜单栏应用，将来自 [Pixabay](https://pixabay.com) 的自然影像循环播放，并作为你真正的桌面背景——这是一个真正的动态壁纸，而不是屏幕保护程序。

![Canopy 浏览界面 — 主视觉背景、My Collection 与 Nature 栏目、搜索框和底部播放栏](docs/screenshots/screenshot.png)

## 功能特色

- **浏览与播放** — Nature/Backgrounds/Animals/Travel 栏目加上自由文本搜索，可通过“加载更多”对 Pixabay 的内容库进行分页浏览
- **多显示器分别设置壁纸** — 为每台已连接的显示器指定不同的视频，或选择 **All** 一次性应用到所有显示器
- **我的收藏（My Collection）** — 播放过的视频会自动保存；可通过拖放或“前移/后移”按钮调整顺序，一键即可移除
- **精确的 Retina 渲染** — 桌面级播放器会同步每块屏幕的实际显示比例，因此 4K 源视频呈现清晰锐利，而不是被放大失真
- **省电设计** — 屏幕锁定/睡眠、低电量模式下会自动暂停播放，也可选择在使用电池时暂停
- **菜单栏控制** — 点击状态栏图标即可打开 Open / Play–Pause / Quit 菜单；主窗口是一个普通的带标题栏窗口，可自由调整大小（⌘Q 退出，无 Dock 图标）
- **多语言支持** — English、한국어、日本語、简体中文

## 系统要求

- macOS 13.0（Ventura）或更高版本
- Xcode 15 或更高版本（用于构建）
- 免费的 [Pixabay API 密钥](https://pixabay.com/api/docs/) — Canopy 不内置共享密钥，因此首次启动时需要在设置中粘贴你自己的密钥

## 安装

可通过 Homebrew 安装——本仓库本身即可作为 tap 使用，无需另建 tap 仓库：

```bash
brew tap mrKangHo/canopy https://github.com/mrKangHo/Canopy
brew install --cask canopy
```

发行版本采用 ad-hoc 签名（未经 Apple 公证），因此首次启动时 Gatekeeper 会以“来自身份不明的开发者”为由加以阻止。请在 `/Applications` 中右键点击 `Canopy.app` 并选择**打开**一次即可放行——此操作仅需在首次启动时进行。

升级到新版本：`brew upgrade --cask canopy`

## 构建方式

本项目通过 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 从 `project.yml` 生成：

```bash
brew install xcodegen   # 仅需一次
xcodegen generate
open Canopy.xcodeproj
```

在 Xcode 中构建并运行（⌘R）即可。仓库中也附带了 `Package.swift`，方便对非界面层代码进行快速的 `swift build`/`swift run` 迭代，但真正生成已签名 `.app`（包含 Info.plist、资源目录和应用图标）的是 XcodeGen 项目。

每当你新增、删除或重命名源文件时，请重新运行 `xcodegen generate`——`.xcodeproj` 是自动生成的产物，不应手动编辑。

## 项目结构

```
Sources/Canopy/
  App/            应用入口 + AppDelegate（状态栏项、菜单）
  MainWindow/      SwiftUI 界面：主视觉浏览页、视频详情、设置、栏目
  Models/          WallpaperManager（应用状态）、DisplayInfo、CategorySection
  PixabayAPI/      网络请求客户端 + 响应模型
  Caching/         视频本地缓存、搜索结果缓存
  WallpaperWindow/ 真正的桌面级 AVPlayer 窗口（每台显示器一个）
Resources/
  Assets.xcassets       应用图标、状态栏图标
  Localizable.xcstrings 字符串目录（en/ko/ja/zh-Hans）
docs/
  icon.png, screenshots/ 本 README 中使用的图片（不属于应用包的一部分）
Casks/
  canopy.rb              Homebrew Cask —— 使本仓库可以充当自己的 tap
```

桌面壁纸本身是通过一个无边框的 `NSWindow` 渲染的，该窗口固定在每块屏幕 Finder 图标图层的正下方（`WallpaperWindow/WallpaperWindowController.swift`）——它完全不涉及系统的桌面图片 API，因此不会受到 macOS 不断收紧该 API 权限的影响。

## 内容与许可

视频内容来自 Pixabay 的流式传输，并在首次播放后缓存到本地，遵循 [Pixabay 内容许可协议](https://pixabay.com/service/license/) 与 [API 使用条款](https://pixabay.com/api/docs/)（禁止永久热链接、搜索结果缓存 24 小时、在设置中展示来源信息）。

## 已知限制

- Pixabay 视频 API 的分辨率上限为 4K（3840×2160）——目前没有适合本应用的真正免费 8K 视频来源；如果你正在评估替代方案，请参阅仓库内的相关讨论
- 发行版本目前为 ad-hoc 签名（此构建背后没有 Apple 开发者计划会员资格），未经过公证、未启用沙盒，也未上架 Mac App Store——若要迁移到 App Sandbox，需要调整桌面级窗口的放置方式和当前的缓存策略
- 基于 `CGDirectDisplayID` 的按显示器记忆功能在重新连接/重启后属于尽力而为的行为（与常见壁纸应用的水平一致，Apple 并不对此提供保证）
