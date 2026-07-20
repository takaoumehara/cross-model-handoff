# cross-model-handoff

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <b>Español</b> ·
  <a href="README.ko.md">한국어</a>
</p>

## Sigue con el mismo proyecto aunque cambies entre varias herramientas de IA

¿Usas IDEs como VS Code, Antigravity o Cursor, o CLIs como Claude Code y Codex, para programar o crear otras cosas con varias IA?

Cuando cambias de herramienta, cross-model-handoff transmite el contexto y la intención del proyecto a la siguiente IA. Ejecuta `/handoff` antes de limpiar el chat o cambiar de herramienta, y la IA generará un prompt de reanudación listo para pegar en la siguiente sesión. Funciona con Claude Code, Codex, Gemini CLI, Antigravity, Cursor y cualquier herramienta que lea `AGENTS.md`.

## For everyone (también para quienes no son ingenieros)

No necesitas ser ingeniero. Puedes usarlo si trabajas con IA para escribir código o crear un proyecto.

### Cuándo usarlo

- Antes de limpiar una conversación larga con la IA
- Cuando se están agotando tus créditos o tu contexto
- Cuando quieres cambiar de Claude Code a Codex, Gemini u otra herramienta
- Cuando quieres parar hoy y continuar más adelante

### Cómo usarlo

1. Ejecuta /handoff mientras todavía recuerdas bien el trabajo.
2. Escribe una nota breve y muestra dos salidas listas para copiar.
3. Copia el Chat resume prompt.
4. Limpia la conversación o cambia de herramienta.
5. Pega el prompt tal cual en la siguiente sesión de IA.

La siguiente IA recibe el objetivo, el estado actual, el archivo exacto de handoff, el siguiente paso y los primeros archivos que debe leer. No tiene que buscar notas antiguas ni preguntarte qué frase de paso debe usar. Usa /handoff-list solo si quieres elegir manualmente entre varios hilos anteriores.

### Qué verás

La salida incluye un prompt de reanudación parecido a este:

~~~text
Continúa con el siguiente trabajo.

Project: my-app
Handoff file: .handoff/2026-07-20-fix-login.md
Goal: Corregir el error de inicio de sesión
State: El fallo está reproducido; la solución aún no está verificada
Next: Ejecutar la prueba de inicio de sesión y revisar el error
Read first: tests/login.test.ts; src/auth/login.ts
Running: none

Empieza por Next. No busques otros archivos .handoff.
~~~

Pega ese bloque en el siguiente chat de IA. La IA solo abrirá el archivo de handoff indicado si necesita más detalles.

Para quienes usan terminal, también aparece este comando:

~~~bash
npx cross-model-handoff resume --file .handoff/2026-07-20-fix-login.md
~~~

Es otra forma de continuar para quienes prefieren trabajar desde la terminal. Puedes elegir entre pegar el prompt de reanudación en el chat o usar el comando de terminal, según tu flujo de trabajo.

## For engineers (para entender el funcionamiento)

La nota de handoff comienza con un Resume Capsule breve y después contiene el registro detallado de la sesión. El Capsule incluye:

- El proyecto y el archivo exacto de handoff
- Una frase de paso con el nombre del repositorio al principio
- El objetivo y el estado actual
- Un siguiente paso concreto
- Los archivos que deben leerse primero
- Procesos, servidores, puertos y worktrees en ejecución

La nota detallada sigue siendo la fuente de verdad y se mantiene por debajo de 80 líneas. Las notas antiguas sin Resume Capsule siguen funcionando mediante su frase de paso y /handoff-list.
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
| `/handoff` | Escribe una nota en `.handoff/` y muestra un prompt de reanudación y un comando de terminal listos para copiar. La nota incluye frase de paso, qué se hizo, estado actual, **estado de ejecución** y siguiente paso. Después es seguro hacer `/clear`. |
| `/handoff-list` | Función de respaldo: lista frases de paso antiguas en `.handoff/` para elegir un hilo manualmente. |
| `/handoff-setup` | Crea `.handoff/` + `AGENTS.md` en un proyecto. Una vez por proyecto. |

Más dos hooks — `SessionStart` (lista tus frases de paso automáticamente al retomar) y `PreCompact` (red de seguridad). Ambos corren solo a nivel del harness: cero coste de contexto.

## El ciclo diario

1. **Trabaja con normalidad.** Nada que mantener. Los commits de git son la fuente de verdad.
2. **Antes de limpiar o cambiar de herramienta:** `/handoff`. Hazlo de forma proactiva — no esperes a que el contexto se llene.
3. **Al volver, en cualquier herramienta:** pega el prompt de reanudación. Usa `/handoff-list` solo si necesitas elegir manualmente un hilo anterior.

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
