# cross-model-handoff

<p align="center">
  <a href="README.md">English</a> ·
  <b>日本語</b> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.ko.md">한국어</a>
</p>

## 複数のAIツールを行き来しても、作業の続きを失わないために

VS Code、Antigravity IDE、Cursor などの IDE ツールや、Claude Code、Codex などの CLI で、複数のAIを使ってプログラミングやその他の創作をしていますか？

複数のAIツールを行き来すると、作業の文脈 (コンテキスト) や設計の意図を、次のAIに正確に渡すのが難しくなります。cross-model-handoffは、そのための仕組みです。AIチャットをクリアする前や、別のAIツールに切り替える前に `/handoff` を実行するだけで、AIが「次のAIへの引き継ぎプロンプト」を自動生成します。

Claude Code、Codex、Gemini CLI、Antigravity、Cursor など、`AGENTS.md` を読むツールならどれでも使えます。

## For everyone (エンジニアでなくても使えます)

これは、AI (IDE や CLI ツール、ブラウザのチャットなど) を使ってコードを書いたり、アプリを作ったり、その他のものをつくったりする人なら誰でも使えます。

### こんな時に使います

- **IDEとCLIを行き来する時**(例: Cursorで作ったコードの続きをClaude Codeに任せたい時)
- **AIツールを切り替える時**(例: Claudeのクレジットが切れたので、GeminiやCodexに切り替えたい時)
- **AIとのチャットが長くなって動きが重くなった時**(一度チャットをクリアしてスッキリさせたい時)
- **今日の作業を止めて、明日また同じ続きから再開したい時**

### 使い方

1. 作業内容をまだ覚えているうちに、AIに対して `/handoff` を実行します。
2. AIがあなたの代わりに短い引き継ぎノートを作成し、画面にコピー用のテキスト(再開プロンプト)とターミナル用コマンドを表示します。
3. 出力された Chat resume prompt をコピーします。
4. チャットをクリアするか、別のAIツール(別のIDEやCLI)に切り替えます。
5. 次のAIセッションの最初に、そのまま貼り付けます。

これだけで、次のAIには「目的、現在の状態、正確な引き継ぎファイル、次にやること、最初に読むべきファイル」が伝わります。過去のチャットを遡って説明し直したり、引き継ぎ用の長文を自分で書いたりする必要はありません。複数の過去スレッドから自分で選びたい時だけ、`/handoff-list` を使います。

### 実際に表示されるもの

たとえば、次のような再開プロンプトが出ます。

~~~text
次の作業を再開してください。

Project: my-app
Handoff file: .handoff/2026-07-20-fix-login.md
Goal: ログインエラーを直す
State: バグは再現済み。修正は未検証
Next: ログインテストを実行し、失敗内容を確認する
Read first: tests/login.test.ts; src/auth/login.ts
Running: none

上記のNextから開始してください。
.handoff内の別ファイルを探さないでください。
~~~

このブロックを次のAIチャットに貼り付けるだけです。詳しい経緯が必要な時だけ、指定されたハンドオフファイルをAIが読みます。

ターミナルを使う人には、もう1つ次のコマンドが表示されます。

~~~bash
npx cross-model-handoff resume --file .handoff/2026-07-20-fix-login.md
~~~

ターミナルから再開したい時に使える、もう1つの入口です。チャットに再開プロンプトを貼る方法と、ターミナルから進める方法のどちらを選んでも構いません。どちらも同じ引き継ぎ情報を使います。

## For engineers (仕組みを知りたい人向け)

ハンドオフノートの先頭には短い Resume Capsule があり、その後ろに詳しいセッション記録が続きます。Capsuleには次の情報が入ります。

- プロジェクト名と正確なハンドオフファイル
- リポジトリ名から始まる合言葉
- 目的と現在の状態
- 具体的な次の一手
- 最初に読むファイル
- 実行中のプロセス、サーバー、ポート、worktree

詳しいノートが唯一の記録で、全体を80行未満に保ちます。Resume Capsuleがない古いノートも、合言葉と `/handoff-list` を使って従来どおり再開できます。
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
| `/handoff` | `.handoff/` にノートを1本書き、コピー用の再開プロンプトとターミナル用コマンドを表示する。合言葉、やったこと、現在の状態、**Running state**、次の一手も記録する。書いたら `/clear` して安全。 |
| `/handoff-list` | 予備機能。`.handoff/` の過去の合言葉を一覧表示し、手動でスレッドを選べる。 |
| `/handoff-setup` | プロジェクトに `.handoff/` + `AGENTS.md` を用意する。プロジェクトごとに1回。 |

加えて2つのフック — `SessionStart`(再開時に合言葉を自動一覧表示)と `PreCompact`(安全網)。どちらもハーネス側だけで動き、コンテキストコストはゼロ。

## 日常の流れ

1. **普段通り作業する。** 維持すべきものはない。git commitが唯一の真実。
2. **クリア・ツール切り替えの前:** `/handoff`。能動的に — コンテキストが埋まるのを待たない。
3. **戻ってきた時(どのツールでも):** 再開プロンプトをそのまま貼り付ける。過去スレッドを手動で選びたい時だけ `/handoff-list` を使う。

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
