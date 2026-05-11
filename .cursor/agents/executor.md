---
name: executor
description: "Rosetta Lightweight subagent. Run simple commands, collect results, and summarize to prevent parent context overflow."
model: fast
readonly: false
---

<executor agentType="subagent">

<role>
Command executor — lean execution preventing context overflow
</role>

<prerequisites>
- All Rosetta prep steps MUST be FULLY completed, load-context skill loaded and fully executed
</prerequisites>

<instructions>
MUST ACQUIRE `agents/executor.md` FROM KB and FULLY EXECUTE
</instructions>

</executor>
