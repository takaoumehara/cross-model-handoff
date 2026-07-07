# cross-model-handoff

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <b>한국어</b>
</p>

컨텍스트를 지우거나 AI 도구를 전환하기 전에 메모 하나를 작성하세요. **암구호(passphrase)**만 말하면 즉시 이어서 작업할 수 있습니다 — Claude Code, Codex, Gemini CLI, Antigravity, Cursor 등 `AGENTS.md`를 읽는 어떤 도구에서도.

## 문제 상황

여러 AI 코딩 도구를 함께 쓰다 보면 두 가지가 반복해서 발목을 잡습니다.

- **작업 도중 크레딧이 떨어진다.** 도구를 전환하면 컨텍스트가 전부 사라진다. 다시 설명하는 비용은 다시 작업하는 것과 다를 바 없다.
- **컨텍스트가 비대해진다.** 세션이 길어질수록 모델은 덜 믿음직해진다. 자동 압축을 기다린다는 건, 모델이 **가장 나쁜** 순간에 요약을 쓰게 한다는 뜻이다.

대부분의 해결책은 무겁다 — 위키, 상태 문서 프로토콜, 동기화 vault. 이건 아니다. 순수 텍스트 파일 세 개뿐.

## 작동 방식

1. **`.handoff/`** — 프로젝트 루트에, 세션마다 짧은 마크다운 메모 한 개.
2. **암구호** — 각 메모에 담긴 기억하기 쉬운 문구. 이름으로 **올바른** 스레드를 재개할 수 있다(같은 브랜치에 병렬 세션이 있을 때 유용).
3. **`AGENTS.md`** — 이미 60개 이상의 AI 도구가 읽는 설정 파일. 어떤 도구에게든 최신 메모를 가리킨다. Claude 전용 요소는 전혀 없다.

## 설치

**Claude Code(플러그인).** 일반 터미널이 아니라 `claude` 세션 안에서:

```
/plugin marketplace add takaoumehara/cross-model-handoff
/plugin install cross-model-handoff@cross-model-handoff
```

**그 외 도구(수동).** [`skills/handoff-setup/SKILL.md`](skills/handoff-setup/SKILL.md)의 내용을 에이전트에 붙여넣고 "여기에 cross-model handoff를 설정해줘"라고 말하면 된다. `.handoff/` + `AGENTS.md`가 만들어진다. 플러그인 런타임 불필요 — Codex, Gemini CLI, Antigravity, Cursor, 어떤 IDE 채팅에서도 작동한다.

<details>
<summary><code>/plugin</code>이 안 되나요?</summary>

| 어디에 입력했는가 | 해결 |
|---|---|
| 일반 터미널(`zsh: no such file or directory: /plugin`) | 셸 명령어가 아니다. 먼저 `claude`를 실행하고, 그 세션 안에서 입력한다. |
| IDE 내장 AI 채팅 / Antigravity 패널(`/plugin isn't available in this environment`) | 그 패널은 진짜 Claude Code 런타임이 아니다. 위의 수동 설정을 사용한다. |
</details>

## 명령어

| 명령어 | 하는 일 |
|---|---|
| `/handoff` | `.handoff/`에 메모 하나를 작성 — 암구호, 완료한 작업, 현재 상태, **실행 상태**(백그라운드 프로세스, 개발 서버, 열린 worktree 등 `git log`로는 알 수 없는 정보), 다음 단계. 작성 후 `/clear`해도 안전. |
| `/handoff-list` | `.handoff/`의 암구호를 목록으로 표시. 하나 골라 재개. |
| `/handoff-setup` | 프로젝트에 `.handoff/` + `AGENTS.md`를 구성. 프로젝트당 한 번. |

여기에 훅 두 개 — `SessionStart`(재개 시 암구호를 자동 목록화)와 `PreCompact`(안전망). 둘 다 하네스 레벨에서만 동작: 컨텍스트 비용 0.

## 일상 흐름

1. **평소처럼 작업한다.** 유지할 것이 없다. git 커밋이 유일한 진실.
2. **지우거나 도구를 전환하기 전:** `/handoff`. 능동적으로 — 컨텍스트가 가득 찰 때까지 기다리지 말 것.
3. **돌아올 때(어떤 도구에서든):** "AGENTS.md를 읽고 이어서 해줘"(또는 `/handoff-list`)라고 말하고, 암구호를 전한다.

## 왜 메모를 능동적으로 써야 하는가

자동 압축은 컨텍스트가 거의 찼을 때 — 모델이 가장 덜 믿음직할 때 — 에만 발동한다. `PreCompact` 훅이 유일한 트리거라면, 다음 세션이 의존할 메모를 **가장 나빠진** 모델에게 쓰게 하는 셈이다. `/handoff`를 일찍 실행하고, 훅은 절대 발동하지 않기를 바라는 예비 수단으로 다뤄라.

## 메모 예시

```markdown
# 2026-07-07 — shoes device UI

Passphrase: "shoes is green, next is landing Moments"

## What was done
- shoes moment용 디바이스 선택기 (components/moments/moment-frame.tsx)

## Current state
- Verified: 타입체크 통과, 비주얼 패리티 green
- Not verified: 모바일 브레이크포인트 미검증

## Running state
- Background processes: none
- Dev servers/ports: none
- Open worktrees: .claude/worktrees/cg-pipeline (작업 중, 삭제 금지)

## Next step
1. 랜딩 페이지 Moments 밴드를 실시간 데이터에 연결

## Files to read next
- components/moments/moment-frame.tsx
```

## 왜 도구 내장 메모리로는 안 되는가

이어지지 않기 때문이다. Claude Code의 메모리는 Codex로 전환하는 순간 쓸모없어진다. `AGENTS.md` + `.handoff/`는 그저 파일이다 — 어디서나 작동하고, 도구별 통합을 만들 필요가 없다.

## 라이선스

MIT
