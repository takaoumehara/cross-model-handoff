# cross-model-handoff

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ja.md">日本語</a> ·
  <b>简体中文</b> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.ko.md">한국어</a>
</p>

面向多智能体编程工作流的、基于口令(passphrase)的会话交接方案。在清空上下文或切换工具之前写一份笔记,之后只需说出口令即可立即恢复 — 适用于 Claude Code、Codex、Gemini CLI、Antigravity、Cursor 等任何读取 `AGENTS.md` 的工具。

## 问题所在

如果你同时使用多个 AI 编程工具(比如同一周内用 Claude Code、Codex、Gemini、Antigravity),就一定会反复遇到这两个问题:

- **额度在任务中途用完。** 切换到另一个工具后,所有上下文都丢失了。重新解释你在做什么,成本几乎和重做一遍一样高。
- **上下文窗口越来越大。** 会话越长,模型的可靠性就悄悄下降 — 随着窗口被填满,检索准确率会实测下降。依赖自动压缩(auto-compaction)意味着摘要恰好是在模型最不可靠的那一刻写出来的。

大多数针对这个问题的解决方案都很"重" — 维护一个 wiki、一套状态文档协议、一个跨会话同步的 vault。这本身就是一种负担 — 有报告指出,仅仅是读取状态文件以跟上进度,每次会话就要消耗 65,000+ 个 token,还没开始做正事。

## 核心思路

不需要任何外部系统,只需三个小机制:

1. **`.handoff/`** — 项目根目录下的纯 Markdown 文件夹。在清空上下文或切换工具之前,写一份简短的笔记。
2. **口令(Passphrase)** — 每份笔记里的一句简短好记的话,让你可以直接说"从那条线程恢复"而不用去猜哪个文件相关。当同一分支上存在并行会话时,这一点尤为重要。
3. **`AGENTS.md`** — 已被 60 多种 AI 编程工具读取的唯一配置文件。它告诉任何工具:先读 `.handoff/` 里最新的笔记,不要碰旧的状态文件,离开前写一份笔记。

这里的一切都不是 Claude 专属的。`AGENTS.md` 和 `.handoff/*.md` 只是 git 仓库里的普通文件 — 任何能读文件的工具都能用。

## 安装

### 作为 Claude Code 插件

```
/plugin marketplace add takaoumehara/cross-model-handoff
/plugin install cross-model-handoff@cross-model-handoff
```

这会自动配置好两个命令和两个 hook(见下文)。

### 手动安装,适用于任何工具

把 `skills/cross-model-handoff-setup/SKILL.md` 复制到你的项目里(或者直接把它的设置步骤粘贴给你的 agent),它会自动搭建好 `.handoff/` 和 `AGENTS.md`。之后的一切都是纯 Markdown,不需要插件。

## 你会得到什么

| | |
|---|---|
| `/handoff-and-clear` | 向 `.handoff/{date}-{slug}.md` 写一份笔记,包含口令、已完成的工作、当前状态、**运行状态**(后台进程、开发服务器、打开的 worktree 等 —— 这些是 `git log` 看不出来的)、下一步、以及接下来要读的文件。写完之后就可以安全地 `/clear` 了。 |
| `/handoff-list` | 扫描 `.handoff/` 并打印出带编号的口令列表,直接选一个就行,不用把每个文件都重新读一遍。 |
| `SessionStart` hook | 在 `clear`/`compact`/`startup` 时,自动把同样的编号索引注入上下文 —— 恢复往往只需要说"继续第 3 个"。 |
| `PreCompact` hook | 安全网:在上下文即将被自动压缩前,强制写一份交接笔记。**这不是主要路径** —— 见下文。 |

## 关于触发时机(请读一下)

自动压缩是在上下文几乎被填满时才触发 —— 也就是模型最不可靠的时候(随着窗口被填满,思考深度和检索准确率都会实测下降)。如果你只依赖 `PreCompact` hook 作为唯一的交接触发点,就等于是让本次会话中状态最差的模型,去写下一次会话要依赖的那份笔记。

把 `/handoff-and-clear` 当作**主动**执行的操作 —— 在会话早期,每次准备切换任务或工具时就去运行它。把 `PreCompact` hook 当作你希望永远不会触发的应急后备方案。

## 笔记示例

```markdown
# 2026-07-07 — shoes device UI

Passphrase: "shoes is green, next is landing Moments"

## What was done
- 为 shoes moment 实现了设备选择器 (components/moments/moment-frame.tsx)
- 修复了 P3 browse 界面里 cx() 的类型错误

## Current state
- Verified: 类型检查通过,视觉一致性脚本 green
- Not verified: 移动端断点未测试

## Running state
- Background processes: none
- Dev servers/ports: none
- Open worktrees/branches: .claude/worktrees/cg-pipeline (任务进行中,不要删除)

## Next step
1. 把落地页的 Moments 板块接入实时数据

## Files to read next
- components/moments/moment-frame.tsx
- app/[locale]/moments/page.tsx
```

## 为什么不直接用某个工具自带的记忆功能?

因为它不能跨工具携带。Claude Code 的项目记忆,在你因为额度用完切换到 Codex 的那一刻就没用了。`AGENTS.md` + `.handoff/` 是能在任何地方都生效的最小方案 —— 因为它只是文件,不需要为每个工具单独构建和维护集成。

## 许可证

MIT
