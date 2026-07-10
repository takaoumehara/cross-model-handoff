# cross-model-handoff

<p align="center">
  <a href="README.md">English</a> ·
  <b>日本語</b> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.ko.md">한국어</a>
</p>

コンテキストをクリアする前・AIツールを切り替える前に、ノートを1本書く。**合言葉(passphrase)**を言うだけで即座に再開できます。Claude Code、Codex、Gemini CLI、Antigravity、Cursor など `AGENTS.md` を読むツールならどれでも。

## 課題

複数のAIコーディングツールを併用すると、必ず2つに悩まされます。

- **クレジットが作業途中で切れる。** ツールを切り替えるとコンテキストが失われる。説明し直すコストは、やり直すのと変わらない。
- **コンテキストが肥大化する。** セッションが長引くほどモデルの精度は落ちる。自動圧縮を待つと、モデルが**最も劣化した瞬間**に要約が書かれる。

多くの対策は重い — Wiki、ステータス文書、同期Vault。これは違います。プレーンなファイル3つだけ。

## 仕組み

1. **`.handoff/`** — プロジェクトルート直下、セッションごとに短いMarkdownノートを1本。
2. **合言葉** — 各ノートに書く覚えやすいフレーズ。形式は `{リポジトリ名}: {フレーズ}`。名前で**正しい**スレッドを再開でき、**どのプロジェクトの続きか**も一目で分かる(同じブランチで並行セッションがある時、そして複数リポジトリを掛け持ちしている時に効く)。
3. **`AGENTS.md`** — 60以上のAIツールが既に読む設定ファイル。どのツールにも最新ノートを指し示す。Claude専用の要素はゼロ。

## インストール

**Claude Code(プラグイン)。** 素のターミナルではなく、`claude` セッションの中で:

```
/plugin marketplace add takaoumehara/cross-model-handoff
/plugin install cross-model-handoff@cross-model-handoff
```

**その他のツール(手動)。** [`skills/handoff-setup/SKILL.md`](skills/handoff-setup/SKILL.md) の中身をエージェントに貼り付けて「ここに cross-model handoff をセットアップして」と言うだけ。`.handoff/` と `AGENTS.md` が作られます。プラグインの仕組みは不要 — Codex、Gemini CLI、Antigravity、Cursor、どのIDEチャットでも動きます。

<details>
<summary><code>/plugin</code> が動かない?</summary>

| どこで打ったか | 対処 |
|---|---|
| 素のターミナル(`zsh: no such file or directory: /plugin`) | シェルコマンドではない。先に `claude` を実行し、そのセッションの中で打つ。 |
| IDE内蔵AIチャット / Antigravityパネル(`/plugin isn't available in this environment`) | そのパネルは本物のClaude Codeランタイムではない。上の手動セットアップを使う。 |
</details>

## コマンド

| コマンド | 役割 |
|---|---|
| `/handoff` | `.handoff/` にノートを1本書く — 合言葉、やったこと、現在の状態、**Running state**(バックグラウンドプロセス・devサーバー・開いているworktreeなど、`git log` では分からない情報)、次の一手。書いたら `/clear` して安全。 |
| `/handoff-list` | `.handoff/` の合言葉を一覧表示。選ぶだけで再開できる。 |
| `/handoff-setup` | プロジェクトに `.handoff/` + `AGENTS.md` を用意する。プロジェクトごとに1回。 |

加えて2つのフック — `SessionStart`(再開時に合言葉を自動一覧表示)と `PreCompact`(安全網)。どちらもハーネス側だけで動き、コンテキストコストはゼロ。

## 日常の流れ

1. **普段通り作業する。** 維持すべきものはない。git commitが唯一の真実。
2. **クリア・ツール切り替えの前:** `/handoff`。能動的に — コンテキストが埋まるのを待たない。
3. **戻ってきた時(どのツールでも):** 「AGENTS.mdを読んで再開して」(または `/handoff-list`)と言い、合言葉を伝える。

## なぜ能動的に書くのか

自動圧縮はコンテキストがほぼ埋まった時 — モデルが最も信頼できない時 — にしか発火しません。`PreCompact` フックだけを頼りにすると、次のセッションが依存するノートを、**最も劣化した**モデルに書かせることになります。`/handoff` は早めに実行し、フックは発火しないことを願う保険として扱いましょう。

## ノートの例

```markdown
# 2026-07-07 — shoes device UI

Passphrase: "shoes-app: shoesは緑、次はlanding Moments"

## What was done
- shoes momentのデバイスセレクター実装 (components/moments/moment-frame.tsx)

## Current state
- Verified: typecheck通過、visual parity green
- Not verified: モバイルブレークポイント未検証

## Running state
- Background processes: none
- Dev servers/ports: none
- Open worktrees: .claude/worktrees/cg-pipeline (作業中、削除しないこと)

## Next step
1. landing pageのMomentsバンドをライブデータに接続

## Files to read next
- components/moments/moment-frame.tsx
```

## なぜツール内蔵メモリではダメなのか

引き継がれないからです。Claude Codeのメモリは、Codexに切り替えた瞬間に役立たずになる。`AGENTS.md` + `.handoff/` は単なるファイル — どこでも動き、ツールごとの統合を作る必要がありません。

## ライセンス

MIT
