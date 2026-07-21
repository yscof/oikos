# Supabase 연동 가이드

오이코스는 **URL/키가 주입된 빌드에서만** 로그인·클라우드가 켜진다.
값을 넣지 않으면 지금까지처럼 완전 오프라인으로 동작하고, 로그인 화면도 뜨지 않는다.
(config-gate: `lib/core/supabase_config.dart`)

## 1. 프로젝트 만들기 (무료)

1. https://supabase.com → New project (무료 티어)
2. **Settings → API** 에서 두 값 복사
   - `Project URL` → `SUPABASE_URL`
   - `anon public` 키 → `SUPABASE_ANON_KEY`

anon 키는 공개돼도 안전하다(RLS로 보호). 절대 노출하면 안 되는 건 `service_role` 키다.

## 2. 로컬에서 켜기

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
```

값 없이 `flutter run` 하면 오프라인 모드(로그인 없음).

## 3. CI/배포에서 켜기

GitHub 저장소 **Settings → Secrets and variables → Actions** 에 등록:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

`ci.yml`의 APK/AAB 빌드가 이 시크릿을 `--dart-define`으로 넘긴다.
시크릿이 없으면 빈 문자열 → 오프라인 APK가 나온다(현재 상태).

## 4. 인증 설정 (FR-101~103)

- **Authentication → Providers → Email**: 기본 켜짐. 이메일/비밀번호 로그인·가입·비밀번호 재설정이 바로 동작한다.
- 개발 중엔 **Email confirmations(이메일 확인)** 를 꺼두면 가입 즉시 로그인된다. 켜두면 확인 메일 후 로그인.
- **소셜 로그인(FR-104, 구글/카카오)**: Authentication → Providers 에서 각 provider의 client id/secret 등록 후, 앱에 버튼 추가(후속 작업).

## 5. 거래 테이블 + RLS (동기화용 — 다음 단계)

로그인은 지금 동작한다. **기록 클라우드 동기화**는 다음 단계이며, 아래 스키마를 미리 만들어 두면 된다. SQL Editor에 붙여넣기:

```sql
create table public.transactions (
  id          text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  kind        text not null,              -- expense | income
  amount_won  integer not null,
  category    text not null,              -- Category enum name
  memo        text not null default '',
  emotion     text,                       -- Emotion enum name | null
  occurred_at timestamptz not null,
  created_at  timestamptz not null,
  updated_at  timestamptz not null default now()
);

alter table public.transactions enable row level security;

-- 본인 행만 읽고 쓴다 (NFR-02)
create policy "own rows only"
  on public.transactions
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

`on delete cascade` 덕분에 계정이 지워지면 거래도 함께 지워진다(FR-105 데이터 삭제).

## 6. 회원 탈퇴 (FR-105)

클라이언트에서 직접 계정을 삭제하려면 `service_role` 권한이 필요해 **Edge Function**으로 처리해야 한다(anon 키로는 불가). 예: `delete-account` 함수에서 `auth.admin.deleteUser(uid)` 호출. 후속 작업으로 남겨둔다. 지금은 로그아웃 + 로컬 데이터 삭제(설정)가 가능하다.

## 7. 배포 전 체크 — 개인정보 문구

계정을 켜면 이메일 등 인증 정보가 서버에 저장되므로, **오프라인 전용일 때의 문구를 바꿔야 한다**:

- `docs/privacy.html` — "데이터 수집 없음/기기에만" → 계정·클라우드 저장 반영
- 설정 화면 하단 "모든 데이터는 이 기기에만 저장됩니다"

현재 라이브 웹 데모(yscof.github.io)는 오프라인 빌드라 위 문구가 아직 정확하다. 계정 켠 빌드를 스토어에 올리기 전에 갱신할 것.

## 현재 상태

- [x] 로그인/가입/비밀번호 재설정 화면, 세션 유지, 로그아웃 (config-gate)
- [ ] 기록 클라우드 동기화 (transactions 테이블, local-first 양방향)
- [ ] 소셜 로그인, 회원 탈퇴 Edge Function
