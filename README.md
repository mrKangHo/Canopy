🇰🇷 [한국어](README.md) | 🇺🇸 [English](README.en.md) | 🇯🇵 [日本語](README.ja.md) | 🇨🇳 [中文](README.zh.md)

<p align="center">
  <img src="docs/icon.png" width="128" height="128" alt="Canopy 앱 아이콘">
</p>

<h1 align="center">Canopy</h1>

<p align="center">
  <a href="https://pixabay.com">Pixabay</a>의 자연 영상을 루프 재생하여 실제 데스크톱 라이브 배경화면으로 감상하는 macOS 메뉴바 앱입니다.
</p>

<p align="center">
  <img src="docs/screenshot.png" alt="Canopy Screenshot" width="800" />
</p>

## 주요 기능

- **탐색 및 재생** — Nature/Backgrounds/Animals/Travel 카테고리와 자유 검색, 페이지네이션 지원
- **모니터별 배경화면** — 연결된 디스플레이마다 다른 영상을 지정하거나 전체 일괄 적용
- **My Collection** — 재생한 영상 즐겨찾기 자동 저장 및 드래그 앤 드롭 정렬
- **정확한 Retina 렌더링** — 각 화면의 실제 배율에 맞춰 4K 원본 영상을 선명하게 렌더링
- **배터리 배려** — 화면 잠금/슬립, 저전력 모드 시 자동 일시정지
- **메뉴바 제어** — 상단 메뉴바 트레이에서 재생/일시정지 및 빠른 제어
- **다국어 지원** — 한국어, English, 日本語, 简体中文

## 설치 (Installation)

### Homebrew
```bash
brew tap mrKangHo/tap
brew install canopy
```

또는 전용 탭 직접 설치:
```bash
brew tap mrKangHo/canopy https://github.com/mrKangHo/Canopy
brew install --cask canopy
```

## 요구 사항

- macOS 13.0 (Ventura) 이상
- 무료 [Pixabay API 키](https://pixabay.com/api/docs/) (앱 설정에서 1회 입력)
