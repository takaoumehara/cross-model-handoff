# cross-model-handoff

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <b>한국어</b>
</p>

멀티 에이전트 코딩 워크플로우를 위한, 암구호(passphrase) 기반 세션 인계 방식. 컨텍스트를 지우거나 도구를 전환하기 전에 메모 하나만 작성해두면, 이름만 말해도 즉시 이어서 작업할 수 있습니다. Claude Code, Codex, Gemini CLI, Antigravity, Cursor 등 `AGENTS.md`를 읽는 어떤 도구에서도 작동합니다.

## 문제 상황

Claude Code, Codex, Gemini, Antigravity처럼 여러 AI 코딩 도구를 함께 사용한다면, 반드시 다음 두 가지를 반복해서 겪게 됩니다.

- **작업 도중 크레딧이 떨어진다.** 다른 도구로 전환하면 컨텍스트가 전부 사라진다. 무엇을 하고 있었는지 다시 설명하는 비용은 그냥 다시 하는 것과 거의 같다.
- **컨텍스트 윈도우가 점점 커진다.** 세션이 길어질수록 모델의 신뢰도는 조용히 떨어진다 — 윈도우가 채워질수록 검색 정확도가 실측으로 하락한다. 자동 압축(auto-compaction)에 의존한다는 것은, 모델이 가장 신뢰할 수 없는 순간에 요약이 작성된다는 뜻이다.

이 문제에 대한 대부분의 해결책은 무겁다 — 위키, 상태 문서 프로토콜, 세션 간 동기화되는 vault. 이것 자체가 세금이 된다 — 어떤 보고서에서는 실제 작업을 시작하기도 전에, 상태 파일을 읽고 따라잡는 데만 세션당 65,000개 이상의 토큰이 소모되었다고 한다.

## 아이디어

외부 시스템 없이, 작은 세 가지 요소만으로:

1. **`.handoff/`** — 프로젝트 루트에 있는 순수 마크다운 폴더. 컨텍스트를 지우거나 도구를 전환하기 직전에, 세션마다 짧은 메모 하나를 작성한다.
2. **암구호(Passphrase)** — 각 메모에 담긴 짧고 기억하기 쉬운 문구. 어떤 파일이 관련 있는지 추측하는 대신 "그 스레드에서 이어서 해줘"라고 말할 수 있게 해준다. 같은 브랜치에서 병렬 세션이 존재할 때 특히 중요하다.
3. **`AGENTS.md`** — 이미 60개 이상의 AI 코딩 도구가 읽고 있는 단 하나의 설정 파일. 어떤 도구에게든 이렇게 알려준다: 먼저 `.handoff/`의 최신 메모를 읽어라, 레거시 상태 파일은 건드리지 마라, 떠나기 전에 메모 하나를 작성해라.

여기 있는 것 중 Claude 전용인 것은 하나도 없다. `AGENTS.md`와 `.handoff/*.md`는 그저 git 저장소 안의 파일일 뿐이다 — 파일을 읽을 수 있는 도구라면 무엇이든 사용할 수 있다.

## 설치

### Claude Code 플러그인으로

```
/plugin marketplace add takaoumehara/cross-model-handoff
/plugin install cross-model-handoff@cross-model-handoff
```

이렇게 하면 명령어 2개와 훅 2개가 자동으로 연결된다(아래 참고).

### 어떤 도구에서든, 수동으로

`skills/cross-model-handoff-setup/SKILL.md`를 프로젝트에 복사하거나(혹은 그 설정 단계를 에이전트에게 그대로 붙여넣으면), `.handoff/`와 `AGENTS.md`가 자동으로 구성된다. 그 이후로는 전부 순수 마크다운 — 플러그인이 필요 없다.

## 얻게 되는 것

| | |
|---|---|
| `/handoff-and-clear` | `.handoff/{date}-{slug}.md`에 메모 하나를 작성한다. 암구호, 완료한 작업, 현재 상태, **실행 상태**(백그라운드 프로세스, 개발 서버, 열려 있는 worktree 등 — `git log`로는 알 수 없는 정보), 다음 단계, 다음에 읽어야 할 파일을 포함한다. 작성 후에는 `/clear`해도 안전하다. |
| `/handoff-list` | `.handoff/`를 스캔해 번호가 매겨진 암구호 목록을 출력한다. 모든 파일을 다시 읽는 대신 번호 하나만 고르면 된다. |
| `SessionStart` 훅 | `clear`/`compact`/`startup` 시점에, 동일한 번호 인덱스를 컨텍스트에 자동으로 주입한다 — 재개는 흔히 "3번 이어서 해줘"로 충분하다. |
| `PreCompact` 훅 | 안전망: 컨텍스트가 자동 압축되기 직전에 인계 메모 작성을 강제한다. **주된 경로는 아니다** — 아래 참고. |

## 발동 시점에 대해 (꼭 읽어보세요)

자동 압축은 컨텍스트가 거의 가득 찼을 때 발동한다 — 즉 모델이 가장 신뢰할 수 없는 상태일 때(윈도우가 채워질수록 사고의 깊이와 검색 정확도 모두 실측으로 저하된다). `PreCompact` 훅만을 유일한 인계 트리거로 삼는다면, 다음 세션이 의존하게 될 메모를, 해당 세션에서 가장 저하된 상태의 모델에게 작성시키는 셈이다.

`/handoff-and-clear`는 세션 초반에, 작업이나 도구를 전환하려 할 때마다 **능동적으로** 실행하는 것으로 다뤄라. `PreCompact` 훅은 절대 발동하지 않기를 바라는 비상용 안전장치로 다뤄라.

## 메모 예시

```markdown
# 2026-07-07 — shoes device UI

Passphrase: "shoes is green, next is landing Moments"

## What was done
- shoes moment용 디바이스 선택기 구현 (components/moments/moment-frame.tsx)
- P3 browse 화면의 cx() 타입 오류 수정

## Current state
- Verified: 타입체크 통과, 비주얼 패리티 스크립트 green
- Not verified: 모바일 브레이크포인트 미검증

## Running state
- Background processes: none
- Dev servers/ports: none
- Open worktrees/branches: .claude/worktrees/cg-pipeline (작업 진행 중, 삭제 금지)

## Next step
1. 랜딩 페이지의 Moments 밴드를 실시간 데이터에 연결

## Files to read next
- components/moments/moment-frame.tsx
- app/[locale]/moments/page.tsx
```

## 왜 한 도구의 내장 메모리만으로는 충분하지 않은가

이어지지 않기 때문이다. Claude Code의 프로젝트 메모리는, 크레딧이 떨어져 Codex로 전환하는 순간 아무 소용이 없어진다. `AGENTS.md` + `.handoff/`는 어디서나 작동하는 가장 작은 방법이다 — 그저 파일일 뿐이므로, 도구마다 통합을 만들고 유지보수할 필요가 없다.

## 라이선스

MIT
