# 작업 재개 가이드 (2026-07-16 갱신)

## 현재 상태

- [x] M0 — CI 그린 셸: 스캐폴드 + main/theme/홈 + 스모크 테스트 + ci.yml + pubspec.lock
- [x] M1 — 데이터 레이어: entry, entry_store(SharedPreferences JSON), clock, formats + 유닛 테스트
- [x] M2 — 기록 시트 + 내역 타임라인 + 라우터('/', '/history', '/settings') + 위젯 테스트
- [x] M3 — 스마트 카테고리 추천기(시간대·금액대·요일 + 지수 감쇠) + 칩 자동 선택
- [x] M4 — 룰 기반 인사이트 엔진(6룰 + steady 폴백) + 홈 헤드라인/근거 시트/주간 소문 + 톤 계약 테스트
- [x] M5 — 설정(내보내기/전체 삭제/라이선스/버전) + 내역 탭 → 항목 수정
- [ ] **M6 (다음 작업)** — 3초 폴리시: 커스텀 금액 키패드, 다크모드/타이포 패스, 앱 아이콘, iOS 빌드 워크플로(workflow_dispatch, macos-latest, --no-codesign)
- [~] M7+ — 스토어 트랙: 개인정보처리방침(docs/privacy.html) ✓, Play 키스토어 + appbundle CI ✓, applicationId `oikos.example.app` 확정(2026-07-19) — 콘솔 등록·업로드 진행 중

## 검증 워크플로

- 각 마일스톤 = 1 커밋 = 1 push(main) = 1 CI 실행(analyze → test → APK 빌드 → 아티팩트)
- 로컬에 Flutter가 있으면 `flutter analyze && flutter test`로 선검증 후 푸시
- APK는 Actions 실행 페이지의 `oikos-apk` 아티팩트로 사이드로드 테스트

## 주의사항

- codegen(build_runner) 의존성 금지
- 모든 사용자 노출 인사이트 문장은 `lib/insight/insight_messages.dart`에만 — 톤 계약은 `test/tone_test.dart`가 기계 검증
- 지출 금액에 빨간색 금지, 게임화 요소 금지 (PLAN.md 원칙)
- 저장 키 `oikos_entries_v1` — 포맷 변경 시 v2 + 마이그레이션
