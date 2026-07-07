# cross-model-handoff

<p align="center">
  <a href="README.md">English</a> ·
  <b>日本語</b> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.ko.md">한국어</a>
</p>

複数のAIツールをまたいで開発するための、合言葉ベースのセッション引き継ぎ。コンテキストをクリアする前・ツールを切り替える前に1本のノートを書くだけで、名前を言うだけで即座に再開できます。Claude Code、Codex、Gemini CLI、Antigravity、Cursor など `AGENTS.md` を読むツールならどれでも対応します。

## 課題

Claude Code・Codex・Gemini・Antigravity のように複数のAIコーディングツールを併用していると、必ず次の2つに直面します。

- **クレジットがセッション途中で切れる。** 別のツールに切り替えると、コンテキストが失われる。何をしていたかを説明し直すコストは、やり直すのとほぼ変わらない。
- **コンテキストウィンドウが肥大化する。** セッションが長引くほどモデルの精度は静かに落ちていく — ウィンドウが埋まるほど検索精度は実測で下がる。自動圧縮に頼るということは、モデルが最も信頼できない瞬間に要約が書かれるということ。

こうした問題への対処は往々にして重い — Wiki、ステータスドキュメントのプロトコル、セッション間で同期するVaultなど。それ自体が税金になる。ある報告では、実際の作業に入る前に状態ファイルを読むだけでセッションあたり65,000トークン以上を消費していたという。

## 発想

外部システムなしの、3つの小さな仕組みだけ。

1. **`.handoff/`** — プロジェクトルート直下のプレーンなMarkdownフォルダ。クリアやツール切り替えの直前に、セッションごとに短いノートを1本書く。
2. **合言葉(Passphrase)** — 各ノートに含まれる、短く覚えやすいフレーズ。「あのスレッドから再開して」と言えるようになる — どのファイルが関係あるか推測する必要がない。同じブランチで並行セッションが存在する場合に効いてくる。
3. **`AGENTS.md`** — 60以上のAIコーディングツールが既に読んでいる、たった1つの設定ファイル。「まず `.handoff/` の最新ノートを読め」「レガシーな状態ファイルには触れるな」「離れる前にノートを1本書け」と、どのツールにも伝える。

ここにあるものはClaude専用のものは何もない。`AGENTS.md` と `.handoff/*.md` は、gitリポジトリの中の単なるファイル — ファイルを読めるツールなら何でも使える。

## インストール

### Claude Codeプラグインとして

```
/plugin marketplace add takaoumehara/cross-model-handoff
/plugin install cross-model-handoff@cross-model-handoff
```

これで2つのコマンドと2つのフックが自動的に配線される(下記参照)。

### どんなツールでも、手動で

`skills/cross-model-handoff-setup/SKILL.md` をプロジェクトにコピーする(あるいはそのセットアップ手順をエージェントに貼り付ける)だけで、`.handoff/` と `AGENTS.md` が自動的に整備される。それ以降は全てプレーンなMarkdown — プラグインは不要。

## 手に入るもの

| | |
|---|---|
| `/handoff-and-clear` | `.handoff/{date}-{slug}.md` にノートを1本書く。合言葉、やったこと、現在の状態、**Running state**(バックグラウンドプロセス、devサーバー、開いているworktreeなど、`git log` では分からない情報)、次の一手、次に読むべきファイルを含む。書いたあとは `/clear` して安全。 |
| `/handoff-list` | `.handoff/` をスキャンし、合言葉を番号付きリストで表示。ファイルを全部読み直す代わりに、番号を選ぶだけで済む。 |
| `SessionStart` フック | `clear`/`compact`/`startup` 時に、同じ番号付きインデックスを自動的にコンテキストへ注入。再開は「3番を続けて」で済むことが多い。 |
| `PreCompact` フック | 安全網:コンテキストが自動圧縮される直前に、ハンドオフノートの作成を強制する。**主経路ではない** — 下記参照。 |

## 発火タイミングについて(重要)

自動圧縮が発火するのは、コンテキストがほぼ埋まった時 — つまりモデルが最も信頼できない状態の時(ウィンドウが埋まるほど、思考の深さも検索精度も実測で劣化する)。`PreCompact` フックだけをハンドオフのトリガーにしていると、次のセッションが依存することになるノートを、そのセッション内で最も劣化したモデルに書かせることになる。

`/handoff-and-clear` は、セッションの早い段階で、タスクやツールを切り替えようとするたびに**能動的に**実行するものとして扱うこと。`PreCompact` フックは、発火しないことを願う緊急時のフォールバックとして扱うこと。

## ノートの例

```markdown
# 2026-07-07 — shoes device UI

Passphrase: "shoesは緑、次はlanding Moments"

## What was done
- shoes momentのデバイスセレクターを実装 (components/moments/moment-frame.tsx)
- P3 browse画面のcx()型エラーを修正

## Current state
- Verified: typecheck通過、visual parityスクリプト green
- Not verified: モバイルブレークポイント未検証

## Running state
- Background processes: none
- Dev servers/ports: none
- Open worktrees/branches: .claude/worktrees/cg-pipeline (作業中、削除しないこと)

## Next step
1. landing pageのMomentsバンドをライブデータに接続

## Files to read next
- components/moments/moment-frame.tsx
- app/[locale]/moments/page.tsx
```

## なぜ1つのツールの内蔵メモリだけで済ませないのか

引き継がれないから。Claude Codeのプロジェクトメモリは、クレジット切れでCodexに切り替えた瞬間に役に立たなくなる。`AGENTS.md` + `.handoff/` は、どこでも動く最小の仕組み — 単なるファイルなので、ツールごとの統合を作ったり維持したりする必要がない。

## ライセンス

MIT
