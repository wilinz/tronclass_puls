# TronClass Plus

TronClass Plus is an unofficial Flutter client that streamlines everyday campus tasks for Guangxi
University of Electronic Technology students. It focuses on fast sign-ins, radar rollcalls, QR
check-ins, and a polished multi-account experience across Android, iOS, macOS, Windows, and the web.

## Key Features

- **Secure Login & Multi-Account Switcher** – GetX-based authentication with encrypted credential
  vault, quick user switching, and login history management.
- **Radar Rollcall Assistant** – Visual radar animation with retry guidance and backend status
  tracking.
- **Interactive Map Picker** – Choose rollcall coordinates on OpenStreetMap tiles, reverse-geocode
  addresses, and automatically convert WGS84 ➜ GCJ-02 before submission.
- **Tronclass Web Portal** – Built-in WebView (webview_flutter) with cookie sync, captcha handling,
  user-agent switching, and cache cleaning.
- **QR & Number Rollcalls** – Dedicated workflows for fast classroom check-ins, including scanning
  and manual code entry.
- **Toast & Notification Helpers** – Custom toast utility, localized messaging, and graceful error
  states.

## Screenshots

| TronClass Portal                                    | Rollcall List                                          |
|-----------------------------------------------------|--------------------------------------------------------|
| ![Radar](screenshot/Screenshot_20251113_023442.png) | ![Accounts](screenshot/Screenshot_20251113_023532.png) |
| Map Picker                                          | Number Rollcall                                        |
| ![Map](screenshot/Screenshot_20251113_031906.png)   | ![Portal](screenshot/Screenshot_20251113_023610.png)   |
| QR Rollcall                                         | Account Manager                                        |
| ![Login](screenshot/Screenshot_20251113_025551.png) | ![QR](screenshot/Screenshot_20251113_030024.png)       |

## Getting Started

1. **Environment** – Install Flutter 3.35.0+ with fvm (`fvm install 3.35.0`).
2. **Dependencies** – `flutter pub get`
3. **Platform Setup**
    - Android: `flutter run -d android`
    - iOS: `cd ios && pod install && cd ..`
    - Desktop/Web: `flutter run -d macos` / `-d windows` / `-d chrome`
4. **Config** – Ensure `assets/` and `fonts/` listed in `pubspec.yaml` are kept in sync when adding
   images or localization files.

## Project Structure

```
lib/
├── auth/              # Login page, controller, saved account storage
├── data/              # Changke client, dio services, storage setup
├── tronclass/         # Feature pages (radar, QR, rollcalls, home)
├── utils/             # Coordinate transforms, helpers
└── webview/           # Custom WebView wrapper with cookies and captcha support
```

## Tech Stack

- **Flutter + GetX** for reactive state and navigation
- **webview_flutter** for the embedded Tronclass portal
- **flutter_map + geolocator + geocoding** for selecting and reverse-geocoding locations
- **encrypt + get_storage** for secure multi-account storage
- **share_plus, permission_handler, dio** for platform capabilities and networking

## TODO

1. 抽象学校层：提供统一登录接口或 WebView 适配层，降低适配其他学校的成本。

---

# TronClass Plus（中文说明）

TronClass Plus 是面向桂电同学的非官方 Tronclass 客户端，主打签到、雷达点名、二维码签到等场景，同时提供多账号、Web
门户和地图定位等工具，支持 Android / iOS / macOS / Windows / Web。

## 核心功能

- **多账号管理**：登录信息加密存储，快速切换、删除、添加账号，登录页也可直接管理账号。
- **雷达点名助手**：动画反馈、状态提示，一键重试，异常信息清晰可见。
- **地图定位**：基于 OpenStreetMap 的地点选择器，支持逆地理编码、WGS84 ➜ GCJ-02 自动转换。
- **Tronclass Web 入口**：内置 WebView 同步 Cookie、验证码弹窗、桌面/移动 UA 切换、缓存清理。
- **二维码 / 数字签到**：独立页面快速扫码或填码，配合 ChangkeClient 完成后台请求。
- **消息提示**：丰富的 Toast 成功/失败提示与本地化文案。

## 截图

请参考上文表格中的示例截图（位于 `screenshot/` 目录）。

## 快速开始

1. 安装 Flutter 3.35.0+（建议使用 fvm 管理）
2. 执行 `flutter pub get` 拉取依赖
3. 根据目标平台运行：`flutter run -d android` / `-d ios` / `-d macos` / `-d windows` / `-d chrome`
4. 如需地图或 Web 功能，请确认本地网络可访问对应服务（中国大陆地区可能需要科学上网）

## 依赖栈

- Flutter + GetX 状态管理
- webview_flutter / flutter_map / geolocator / geocoding
- encrypt + get_storage 密钥存储
- dio, share_plus, permission_handler 等常用插件

欢迎 Issue / PR 交流改进，祝使用愉快!
