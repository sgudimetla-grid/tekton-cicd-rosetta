---
name: executor
description: Rosetta Lightweight subagent. Run simple commands, collect results, and summarize to prevent parent context overflow.
model: haiku
baseSchema: docs/schemas/agent.md
---

<executor agentType="subagent">

<role>
Rosetta-defined subagent — see KB.
</role>

<prerequisites>
- Rosetta prep steps completed
</prerequisites>

<instructions>
MUST ACQUIRE `agents/executor.md` FROM KB and FULLY EXECUTE
</instructions>

</executor>
