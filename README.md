# 오이코스 (Oikos)

> 돈을 관리하게 만드는 것이 아니라, 자연스럽게 이해하게 만든다.

그리스어 οἶκος(집·가정, economy의 어원)에서 이름을 딴 가계부 앱.
Google Play와 iOS App Store 동시 출시를 목표로 하는 Flutter 앱입니다.

## 제품 원칙 (요약)

- 첫 화면은 거래내역이 아니라 **"내 금융 상태" 한 문장** — 날씨앱이 날씨를 보여주듯
- 기록은 **평균 3초**: 금액 입력 → 스마트 카테고리 추천 → 저장
- **Invisible AI**: 룰 기반 온디바이스 인사이트. "AI"라는 단어는 앱 어디에도 없음
- 게임화 없음(포인트·배지·스트릭 X), 알림 남발 없음, 빨간 숫자 없음 — 편안함이 기본값
- 완전 오프라인: 모든 데이터는 기기에만 저장

## 기술

- Flutter (android / ios / web), Material 3, 시드 컬러 `#5E7A66`
- Riverpod + go_router + shared_preferences (codegen 없음)
- 로컬 Flutter SDK 없이 개발 — 검증·빌드는 GitHub Actions에서 수행

## 개발 워크플로

1. main에 푸시 → Actions가 `analyze` → `test` → `apk` 빌드
2. Actions 실행 페이지에서 APK 아티팩트를 받아 기기에서 확인

전체 구현 계획은 [docs/PLAN.md](docs/PLAN.md), 재개 방법은 [docs/RESUME.md](docs/RESUME.md) 참고.
