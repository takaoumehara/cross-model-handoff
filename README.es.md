# cross-model-handoff

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <b>Español</b> ·
  <a href="README.ko.md">한국어</a>
</p>

Escribe una nota antes de limpiar el contexto o cambiar de herramienta de IA. Retoma al instante nombrando su **frase de paso (passphrase)** — en Claude Code, Codex, Gemini CLI, Antigravity, Cursor, o cualquier herramienta que lea `AGENTS.md`.

## El problema

Trabajando con varias herramientas de IA, dos cosas molestan constantemente:

- **Los créditos se agotan a mitad de tarea.** Cambias de herramienta y pierdes todo el contexto. Volver a explicar cuesta tanto como rehacer el trabajo.
- **El contexto se satura.** Cuanto más dura una sesión, menos fiable es el modelo. Esperar a la auto-compactación significa que el resumen se escribe en el *peor* momento del modelo.

La mayoría de las soluciones son pesadas — una wiki, un protocolo de documentos de estado, un vault sincronizado. Esta no. Son tres archivos de texto plano.

## Cómo funciona

1. **`.handoff/`** — una nota markdown breve por sesión, en la raíz del proyecto.
2. **Una frase de paso** — una frase memorable en cada nota, para retomar el hilo *correcto* por su nombre (importa cuando hay sesiones paralelas en la misma rama).
3. **`AGENTS.md`** — el archivo de configuración que 60+ herramientas de IA ya leen. Apunta a cualquier herramienta hacia la última nota. Nada aquí es específico de Claude.

## Instalación

**Claude Code (plugin).** Dentro de una sesión `claude` — no en una terminal normal:

```
/plugin marketplace add takaoumehara/cross-model-handoff
/plugin install cross-model-handoff@cross-model-handoff
```

**Cualquier otra herramienta (manual).** Pega [`skills/handoff-setup/SKILL.md`](skills/handoff-setup/SKILL.md) en tu agente y di "configura cross-model handoff aquí". Crea `.handoff/` + `AGENTS.md`. No hace falta runtime de plugins — funciona en Codex, Gemini CLI, Antigravity, Cursor, o cualquier chat de IDE.

<details>
<summary>¿<code>/plugin</code> no funciona?</summary>

| Dónde lo escribiste | Solución |
|---|---|
| Terminal normal (`zsh: no such file or directory: /plugin`) | No es un comando de shell. Ejecuta `claude` primero, y escríbelo dentro de esa sesión. |
| Chat de IA de un IDE / panel de Antigravity (`/plugin isn't available in this environment`) | Ese panel no es el runtime real de Claude Code. Usa la configuración manual de arriba. |
</details>

## Comandos

| Comando | Qué hace |
|---|---|
| `/handoff` | Escribe una nota en `.handoff/` — frase de paso, qué se hizo, estado actual, **estado de ejecución** (procesos en segundo plano, servidores de desarrollo, worktrees abiertos — lo que `git log` no puede decirte), siguiente paso. Después es seguro hacer `/clear`. |
| `/handoff-list` | Lista las frases de paso en `.handoff/` para elegir una y retomar. |
| `/handoff-setup` | Crea `.handoff/` + `AGENTS.md` en un proyecto. Una vez por proyecto. |

Más dos hooks — `SessionStart` (lista tus frases de paso automáticamente al retomar) y `PreCompact` (red de seguridad). Ambos corren solo a nivel del harness: cero coste de contexto.

## El ciclo diario

1. **Trabaja con normalidad.** Nada que mantener. Los commits de git son la fuente de verdad.
2. **Antes de limpiar o cambiar de herramienta:** `/handoff`. Hazlo de forma proactiva — no esperes a que el contexto se llene.
3. **Al volver, en cualquier herramienta:** di "lee AGENTS.md y retoma" (o `/handoff-list`), y nombra la frase de paso.

## Por qué escribir la nota de forma proactiva

La auto-compactación solo se activa cuando el contexto está casi lleno — cuando el modelo es menos fiable. Si el hook `PreCompact` es tu único disparador, la *peor* versión del modelo escribe la nota de la que depende la siguiente sesión. Ejecuta `/handoff` temprano; trata el hook como un respaldo que esperas que nunca se active.

## Ejemplo de nota

```markdown
# 2026-07-07 — shoes device UI

Passphrase: "shoes-app: shoes is green, next is landing Moments"

## What was done
- Selector de dispositivo para el moment de shoes (components/moments/moment-frame.tsx)

## Current state
- Verified: el typecheck pasa, paridad visual green
- Not verified: breakpoint móvil sin probar

## Running state
- Background processes: none
- Dev servers/ports: none
- Open worktrees: .claude/worktrees/cg-pipeline (en curso, no borrar)

## Next step
1. Conectar la sección Moments de la landing a datos en vivo

## Files to read next
- components/moments/moment-frame.tsx
```

## ¿Por qué no la memoria integrada de una herramienta?

Porque no viaja contigo. La memoria de Claude Code es inútil en cuanto cambias a Codex. `AGENTS.md` + `.handoff/` son solo archivos — funcionan en todas partes, sin integración por herramienta que construir.

## Licencia

MIT
