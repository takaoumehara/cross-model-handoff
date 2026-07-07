# cross-model-handoff

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ja.md">日本語</a> ·
  <b>简体中文</b> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.ko.md">한국어</a>
</p>

在清空上下文或切换 AI 工具之前,写一份笔记。之后只要说出它的**口令(passphrase)**即可立即恢复 —— 适用于 Claude Code、Codex、Gemini CLI、Antigravity、Cursor 等任何读取 `AGENTS.md` 的工具。

## 问题所在

同时使用多个 AI 编程工具时,有两件事反复困扰你:

- **额度在任务中途用完。** 切换工具后上下文全丢了。重新解释的成本和重做一遍差不多。
- **上下文越来越臃肿。** 会话越长,模型越不可靠。等自动压缩,意味着摘要恰好写在模型**最差**的那一刻。

大多数方案都很重 —— wiki、状态文档协议、跨会话同步的 vault。这个不是,只有三个纯文本文件。

## 工作原理

1. **`.handoff/`** —— 项目根目录下,每次会话一份简短的 markdown 笔记。
2. **口令** —— 每份笔记里一句好记的话,让你按名字恢复**正确**的线程(同一分支有并行会话时尤其有用)。
3. **`AGENTS.md`** —— 已被 60 多种 AI 工具读取的配置文件。它为任何工具指向最新的笔记。这里没有任何 Claude 专属的东西。

## 安装

**Claude Code(插件)。** 在 `claude` 会话内 —— 不是普通终端:

```
/plugin marketplace add takaoumehara/cross-model-handoff
/plugin install cross-model-handoff@cross-model-handoff
```

**其他任何工具(手动)。** 把 [`skills/handoff-setup/SKILL.md`](skills/handoff-setup/SKILL.md) 的内容粘贴给你的 agent,说"在这里设置 cross-model handoff"。它会搭建好 `.handoff/` + `AGENTS.md`。不需要插件运行时 —— 在 Codex、Gemini CLI、Antigravity、Cursor 或任何 IDE 聊天里都能用。

<details>
<summary><code>/plugin</code> 不好用?</summary>

| 你在哪里输入 | 解决办法 |
|---|---|
| 普通终端(`zsh: no such file or directory: /plugin`) | 它不是 shell 命令。先运行 `claude`,再在那个会话里输入。 |
| IDE 自带 AI 聊天 / Antigravity 面板(`/plugin isn't available in this environment`) | 那个面板不是真正的 Claude Code 运行时。用上面的手动设置。 |
</details>

## 命令

| 命令 | 作用 |
|---|---|
| `/handoff` | 往 `.handoff/` 写一份笔记 —— 口令、已完成的工作、当前状态、**运行状态**(后台进程、开发服务器、打开的 worktree —— 这些是 `git log` 看不出来的)、下一步。写完就可以安全 `/clear`。 |
| `/handoff-list` | 列出 `.handoff/` 里的口令,选一个即可恢复。 |
| `/handoff-setup` | 在项目里搭建 `.handoff/` + `AGENTS.md`。每个项目做一次。 |

外加两个 hook —— `SessionStart`(恢复时自动列出你的口令)和 `PreCompact`(安全网)。两者都只在框架层运行:零上下文开销。

## 日常流程

1. **正常工作。** 没有要维护的东西。git commit 就是唯一真相。
2. **清空或切换工具之前:** `/handoff`。主动去做 —— 别等上下文塞满。
3. **回来时(用任何工具):** 说"读一下 AGENTS.md 然后恢复"(或 `/handoff-list`),再说出口令。

## 为什么要主动写笔记

自动压缩只在上下文快满时才触发 —— 也就是模型最不可靠的时候。如果 `PreCompact` hook 是你唯一的触发点,那就是让**最差**版本的模型,去写下一次会话要依赖的笔记。尽早运行 `/handoff`,把 hook 当作你希望永远不会触发的后备。

## 笔记示例

```markdown
# 2026-07-07 — shoes device UI

Passphrase: "shoes is green, next is landing Moments"

## What was done
- shoes moment 的设备选择器 (components/moments/moment-frame.tsx)

## Current state
- Verified: 类型检查通过,视觉一致性 green
- Not verified: 移动端断点未测试

## Running state
- Background processes: none
- Dev servers/ports: none
- Open worktrees: .claude/worktrees/cg-pipeline (任务进行中,不要删除)

## Next step
1. 把落地页的 Moments 板块接入实时数据

## Files to read next
- components/moments/moment-frame.tsx
```

## 为什么不用工具自带的记忆?

因为它不能跨工具携带。你一切换到 Codex,Claude Code 的记忆就没用了。`AGENTS.md` + `.handoff/` 只是文件 —— 到处都能用,不需要为每个工具单独做集成。

## 许可证

MIT
