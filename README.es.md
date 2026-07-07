# cross-model-handoff

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <b>Español</b> ·
  <a href="README.ko.md">한국어</a>
</p>

Traspaso de sesión basado en frase de paso (passphrase) para flujos de trabajo con múltiples agentes de codificación. Escribe una nota antes de limpiar el contexto o cambiar de herramienta, y retoma al instante con solo nombrarla — funciona con Claude Code, Codex, Gemini CLI, Antigravity, Cursor, o cualquier herramienta que lea `AGENTS.md`.

## El problema

Si trabajas con varias herramientas de IA para programar — digamos Claude Code, Codex, Gemini y Antigravity en la misma semana — te vas a topar constantemente con dos cosas:

- **Los créditos se agotan a mitad de tarea** en una herramienta. Cambias a otra y pierdes todo el contexto. Volver a explicar qué estabas haciendo cuesta casi lo mismo que simplemente rehacerlo.
- **Las ventanas de contexto se saturan.** Cuanto más dura una sesión, menos fiable se vuelve el modelo en silencio — la precisión de recuperación cae de forma medible a medida que se llena la ventana. Depender de la auto-compactación significa que el resumen se escribe justo en el momento en que el modelo es menos confiable.

La mayoría de las soluciones a esto son pesadas: una wiki, un protocolo de documentos de estado, un vault sincronizado entre sesiones. Eso mismo se convierte en un impuesto — un informe señaló que se consumían más de 65,000 tokens por sesión solo leyendo archivos de estado para ponerse al día, antes de hacer ningún trabajo real.

## La idea

Tres piezas pequeñas, sin ningún sistema externo:

1. **`.handoff/`** — una carpeta en markdown plano en la raíz del proyecto. Una nota breve por sesión, escrita justo antes de limpiar el contexto o cambiar de herramienta.
2. **Una frase de paso (passphrase)** — una frase corta y fácil de recordar en cada nota, para poder decir "retoma desde ese hilo" en lugar de adivinar qué archivo es el relevante. Esto importa en cuanto tienes sesiones paralelas en la misma rama.
3. **`AGENTS.md`** — el único archivo de configuración que ya leen más de 60 herramientas de codificación con IA. Le dice a cualquier herramienta: lee primero la última nota en `.handoff/`, no toques archivos de estado heredados, escribe una nota antes de irte.

Nada de esto es específico de Claude. `AGENTS.md` + `.handoff/*.md` son solo archivos en un repositorio git — cualquier herramienta que pueda leer un archivo puede usarlo.

## Instalación

Hay dos formas de instalarlo, y cuál funciona depende de dónde estés escribiendo el comando. Lee la tabla de solución de problemas más abajo si `/plugin` no hace lo que esperas — normalmente significa que estás en un lugar que no es el runtime real de Claude Code CLI.

### Método A — Plugin de Claude Code (terminal)

Esta es la vía oficialmente soportada. Solo funciona dentro de la sesión real de Claude Code CLI — no en una shell normal, y no de forma fiable dentro de todos los paneles de chat integrados en un IDE (ver la tabla de abajo).

1. Abre una terminal e inicia Claude Code:
   ```bash
   claude
   ```
   `/plugin` es un comando que escribes **dentro** de esta sesión interactiva — no es un comando de shell. Si ejecutas `/plugin marketplace add ...` directamente en tu prompt de zsh/bash (o lo rediriges a `bash`), falla con algo como `zsh: no such file or directory: /plugin`. Ese error significa que nunca llegaste a entrar en una sesión de Claude Code.

2. Una vez dentro de la sesión de Claude Code, ejecuta:
   ```
   /plugin marketplace add takaoumehara/cross-model-handoff
   /plugin install cross-model-handoff@cross-model-handoff
   ```

Esto conecta automáticamente dos comandos y dos hooks (ver más abajo).

### Método B — Configuración manual (funciona en todas partes, sin necesidad de sistema de plugins)

Usa esto si estás en Codex, Gemini CLI, Antigravity, Cursor, el chat de IA propio de un IDE, o en cualquier lugar donde `/plugin` no se reconozca o diga algo como `/plugin isn't available in this environment`.

1. Pega el contenido de [`skills/cross-model-handoff-setup/SKILL.md`](skills/cross-model-handoff-setup/SKILL.md) en el chat de tu agente (o simplemente dale la URL cruda de GitHub y pídele que la lea y la siga).
2. Dile: "Configura cross-model handoff en este proyecto."
3. Creará `.handoff/` y `AGENTS.md` por ti. Todo lo demás es markdown plano e instrucciones normales — no se necesita ningún runtime de plugins.

Una vez configurado, `/handoff-and-clear` y `/handoff-list` tampoco son obligatorios. Si tu herramienta no soporta comandos de barra personalizados, simplemente pega el contenido de [`commands/handoff-and-clear.md`](commands/handoff-and-clear.md) como un prompt normal cada vez que quieras escribir una nota de traspaso.

### Solución de problemas: ¿dónde funciona realmente `/plugin`?

| Dónde lo escribes | Qué ocurre | Qué hacer |
|---|---|---|
| Un prompt de terminal normal (zsh/bash), fuera de Claude Code | `zsh: no such file or directory: /plugin` | `/plugin` no es un comando de shell. Ejecuta primero `claude`, y luego escribe el comando dentro de esa sesión (Método A) |
| Dentro de la sesión real de Claude Code CLI (después de ejecutar `claude`) | Funciona | Esta es la vía prevista |
| El chat de IA propio de un IDE que no es el motor real de Claude Code (varía según el IDE y la versión — algunos muestran un panel "Claude Code" que en realidad usa otro motor de agente por debajo) | Puede decir `/plugin isn't available in this environment`, o simplemente no reconocerlo como comando | Usa el Método B — no depende de ningún sistema de plugins |
| El panel "Claude Code" integrado en Antigravity | `/plugin isn't available in this environment` | Esperado — ese panel ejecuta el propio motor de agente de Antigravity, no el runtime de plugins de Claude Code. Usa el Método B |

## Cómo usarlo (en el día a día)

Una vez instalado (Método A o B), todo el flujo se reduce a tres momentos.

1. **Trabajas con normalidad.** No hay nada que hacer — ningún archivo de estado que mantener, ninguna wiki que actualizar. Los commits de git son la única fuente de verdad.
2. **Estás a punto de limpiar el contexto o cambiar de herramienta.** Ejecuta `/handoff-and-clear` (o, con el Método B, simplemente di "escribe una nota de traspaso"). Escribe una nota en `.handoff/` con una frase de paso. Hazlo de forma proactiva — no esperes a que el contexto se sature.
3. **Vuelves, en cualquier herramienta.** Di "lee AGENTS.md y retoma" (o `/handoff-list` si no estás seguro de en qué hilo estabas). Nombra la frase de paso, o el número, y el agente lee esa nota y retoma justo donde lo dejaste.

Eso es todo el ciclo. Sin paneles de control, sin mantenimiento diario.

## Qué obtienes

| | |
|---|---|
| `/handoff-and-clear` | Escribe una nota en `.handoff/{date}-{slug}.md` con una frase de paso, qué se hizo, el estado actual, **estado de ejecución** (procesos en segundo plano, servidores de desarrollo, worktrees abiertos — lo que `git log` no puede decirte), el siguiente paso, y los archivos que hay que leer a continuación. Después es seguro hacer `/clear`. |
| `/handoff-list` | Escanea `.handoff/` e imprime una lista numerada de frases de paso, para que puedas elegir una en lugar de releer todos los archivos. |
| Hook `SessionStart` | En `clear`/`compact`/`startup`, inyecta automáticamente ese mismo índice numerado en el contexto — retomar suele ser tan simple como decir "continúa con el #3". |
| Hook `PreCompact` | Red de seguridad: obliga a escribir una nota de traspaso si el contexto está a punto de auto-compactarse. **No es la vía principal** — ver más abajo. |

## Sobre el momento de activación (léelo)

La auto-compactación se activa cuando el contexto está casi lleno — es decir, cuando el modelo está en su punto menos fiable (tanto la profundidad de razonamiento como la precisión de recuperación se degradan de forma medible a medida que se llena una ventana). Si dependes del hook `PreCompact` como único disparador de traspaso, estás pidiéndole a la versión más degradada del modelo en tu sesión que escriba la nota de la que dependerá la siguiente sesión.

Trata `/handoff-and-clear` como algo que ejecutas **de forma proactiva**, más temprano en una sesión, cada vez que estás a punto de cambiar de tarea o de herramienta. Trata el hook `PreCompact` como el respaldo de emergencia que esperas que nunca se active.

## Ejemplo de nota

```markdown
# 2026-07-07 — shoes device UI

Passphrase: "shoes is green, next is landing Moments"

## What was done
- Implementado el selector de dispositivo para el moment de shoes (components/moments/moment-frame.tsx)
- Corregidos los errores de tipo de cx() en la pantalla P3 browse

## Current state
- Verified: el typecheck pasa, el script de paridad visual está en verde
- Not verified: el breakpoint móvil no se ha probado

## Running state
- Background processes: none
- Dev servers/ports: none
- Open worktrees/branches: .claude/worktrees/cg-pipeline (tarea en curso, no borrar)

## Next step
1. Conectar la sección Moments de la landing page a datos en vivo

## Files to read next
- components/moments/moment-frame.tsx
- app/[locale]/moments/page.tsx
```

## ¿Por qué no usar simplemente la memoria integrada de una herramienta?

Porque no viaja contigo. La memoria de proyecto de Claude Code no sirve de nada en cuanto cambias a Codex porque se te acabaron los créditos. `AGENTS.md` + `.handoff/` es lo más pequeño que funciona en todas partes, porque son solo archivos — no hay ninguna integración por herramienta que construir ni mantener.

## Licencia

MIT
