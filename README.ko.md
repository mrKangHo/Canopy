<p align="center">
  <a href="README.md">English</a> · <b>한국어</b> · <a href="README.ja.md">日本語</a> · <a href="README.zh-Hans.md">简体中文</a>
</p>

<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Canopy 앱 아이콘">
</p>

# Canopy

[Pixabay](https://pixabay.com)의 자연 영상을 루프 재생해서 실제 데스크톱 배경화면으로 보여주는 macOS 메뉴바 앱입니다 — 스크린세이버가 아니라 진짜 라이브 배경화면입니다.

![Canopy 브라우징 화면 — 히어로 배경, My Collection/Nature 선반, 검색창, 하단 재생 바](docs/screenshots/screenshot.png)

## 주요 기능

- **탐색 및 재생** — Nature/Backgrounds/Animals/Travel 선반과 자유 검색, Pixabay 카탈로그를 페이지네이션("Load More")으로 계속 불러올 수 있습니다
- **모니터별 배경화면** — 연결된 모니터마다 다른 영상을 지정하거나, **All**로 모든 모니터에 한 번에 적용할 수 있습니다
- **My Collection** — 재생했던 영상이 자동으로 저장됩니다. 드래그 앤 드롭이나 이동 버튼으로 순서를 바꾸고, 클릭 한 번으로 삭제할 수 있습니다
- **정확한 Retina 렌더링** — 데스크톱 레벨 플레이어가 각 화면의 실제 배율에 맞춰 그려서, 4K 원본 영상이 업스케일되지 않고 선명하게 표시됩니다
- **배터리 배려** — 화면 잠금/슬립, 저전력 모드 시 자동으로 일시정지되며, 배터리 사용 중 일시정지도 선택할 수 있습니다
- **메뉴바 제어** — 상태바 아이콘을 클릭하면 Open / Play–Pause / Quit 메뉴가 뜹니다. 메인 창은 평범한 타이틀 바 창이라 크기 조절도 가능합니다(⌘Q로 종료, Dock 아이콘 없음)
- **다국어 지원** — English, 한국어, 日本語, 简体中文

## 요구 사항

- macOS 13.0(Ventura) 이상
- Xcode 15 이상 (빌드 시)
- 무료 [Pixabay API 키](https://pixabay.com/api/docs/) — Canopy는 공유 키를 내장하지 않으므로, 최초 실행 시 설정 화면에 본인 키를 직접 입력해야 합니다

## 설치

Homebrew로 설치할 수 있습니다 — 이 저장소 자체가 탭(tap) 역할을 겸하므로 별도의 탭 저장소가 필요 없습니다:

```bash
brew tap mrKangHo/canopy https://github.com/mrKangHo/Canopy
brew install --cask canopy
```

배포되는 빌드는 ad-hoc 서명(Apple 공증 없음)이라 처음 실행 시 Gatekeeper가 "확인되지 않은 개발자"로 막습니다. `/Applications`에서 `Canopy.app`을 우클릭한 뒤 **열기**를 한 번만 선택하면 이후로는 정상 실행됩니다.

새 버전으로 업데이트: `brew upgrade --cask canopy`

## 빌드하기

이 프로젝트는 [XcodeGen](https://github.com/yonaskolb/XcodeGen)을 통해 `project.yml`로부터 생성됩니다:

```bash
brew install xcodegen   # 최초 1회
xcodegen generate
open Canopy.xcodeproj
```

Xcode에서 빌드/실행(⌘R)하면 됩니다. UI가 아닌 계층을 빠르게 반복 작업하고 싶을 때 쓸 수 있는 `Package.swift`도 포함되어 있지만, 실제 서명된 `.app`(Info.plist, 에셋 카탈로그, 앱 아이콘 포함)을 만드는 건 XcodeGen 프로젝트 쪽입니다.

소스 파일을 추가/삭제/이름 변경할 때마다 `xcodegen generate`를 다시 실행하세요 — `.xcodeproj`는 자동 생성되는 결과물이라 직접 수정하는 대상이 아닙니다.

## 프로젝트 구조

```
Sources/Canopy/
  App/            앱 진입점 + AppDelegate(상태바 아이템, 메뉴)
  MainWindow/      SwiftUI 화면: 히어로 브라우징 뷰, 영상 상세, 설정, 선반
  Models/          WallpaperManager(앱 상태), DisplayInfo, CategorySection
  PixabayAPI/      네트워킹 클라이언트 + 응답 모델
  Caching/         영상 로컬 캐시, 검색 결과 캐시
  WallpaperWindow/ 실제 데스크톱 레벨 AVPlayer 창(디스플레이별로 하나씩)
Resources/
  Assets.xcassets       앱 아이콘, 상태바 아이콘
  Localizable.xcstrings String Catalog(en/ko/ja/zh-Hans)
docs/
  icon.png, screenshots/ 이 README에서 쓰는 이미지(앱 번들에는 포함되지 않음)
Casks/
  canopy.rb              Homebrew Cask — 이 저장소가 자체 탭 역할을 하게 해줍니다
```

실제 배경화면은 각 화면의 Finder 아이콘 레이어 바로 아래에 고정된 보더리스 `NSWindow`로 렌더링됩니다(`WallpaperWindow/WallpaperWindowController.swift`) — 시스템 배경화면 API를 전혀 건드리지 않으므로, macOS가 그 API 권한을 점점 조이더라도 영향을 받지 않습니다.

## 콘텐츠 및 라이선스

영상 콘텐츠는 Pixabay에서 스트리밍되며 최초 재생 후 로컬에 캐시됩니다. [Pixabay 콘텐츠 라이선스](https://pixabay.com/service/license/)와 [API 이용약관](https://pixabay.com/api/docs/)을 따릅니다(영구 핫링킹 금지, 검색 결과 24시간 캐싱, 설정 화면에 출처 표시).

## 알려진 제약사항

- Pixabay 영상 API는 4K(3840×2160)가 상한선입니다 — 이 앱에 적합한 진짜 무료 8K 영상 소스는 현재 존재하지 않습니다. 대안을 검토 중이시라면 저장소 내 관련 논의를 참고하세요
- 배포 빌드는 ad-hoc 서명 상태(이 빌드 뒤에 Apple Developer Program 멤버십이 없음)이며 공증도, 샌드박스도, Mac App Store 등록도 되어 있지 않습니다 — App Sandbox로 전환하려면 데스크톱 레벨 윈도우 배치와 현재의 캐싱 방식을 손봐야 합니다
- `CGDirectDisplayID` 기반의 디스플레이별 기억 기능은 재연결/재부팅 시 최선을 다해 동작하는 수준입니다(일반적인 배경화면 앱들과 동일한 수준이며, Apple이 이를 보장하지는 않습니다)
