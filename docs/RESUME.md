# 작업 재개 가이드 (2026-07-16 중단 시점)

## 현재 상태

- [x] 계획 승인 완료 → `docs/PLAN.md` (원본: `C:\Users\user\.claude\plans\3-adaptive-meteor.md`)
- [x] **M0 일부**: didim에서 android/ios/web 스캐폴드 복사, 번들 ID `com.oikos.app`으로 개명(gradle 2곳, pbxproj 6곳, MainActivity 경로/패키지), 앱 표시명 `오이코스`, web 매니페스트/타이틀/테마색 `#5E7A66`, `pubspec.yaml`, README
- [ ] **M0 나머지 (다음 작업)**: `lib/main.dart` + `lib/app/theme.dart` + 플레이스홀더 홈, `test/app_smoke_test.dart`, `.github/workflows/ci.yml` (setup-java temurin 17 → subosito/flutter-action → pub get → analyze → test → build apk → APK·pubspec.lock 아티팩트)
- [ ] M1~M6: PLAN.md 마일스톤 순서대로
- [ ] GitHub 저장소가 아직 없다면: github.com/new 에서 `oikos` (public, README 없이) 생성 후 push

## 재개 프롬프트 (아래를 복사해서 Claude Code에 붙여넣기)

```
c:\Users\user\Desktop\oikos 프로젝트 작업을 재개해줘.
docs/PLAN.md(승인된 구현 계획)와 docs/RESUME.md(중단 시점 상태)를 읽고,
M0 나머지(main.dart, theme, 스모크 테스트, ci.yml)부터 이어서
PLAN.md의 마일스톤 순서(M1 데이터 레이어 → M2 기록/내역 → M3 카테고리 추천기
→ M4 인사이트 엔진 → M5 설정/수정)대로 구현해줘.
마일스톤마다 커밋하고 main에 푸시해서 GitHub Actions로 검증해줘.
로컬에 Flutter가 없으니 모든 검증은 CI로 한다는 제약을 지켜줘.
```

## 주의사항

- 로컬 Flutter SDK 없음 → `flutter` 명령 실행 불가, 파일은 수작업 작성, 검증은 CI
- codegen(build_runner) 의존성 금지
- `pubspec.lock`이 아직 없음 → 첫 CI 실행에서 아티팩트로 받아 커밋
- applicationId(`com.oikos.app`)는 첫 Play Console 업로드 전 최종 확정 필요
