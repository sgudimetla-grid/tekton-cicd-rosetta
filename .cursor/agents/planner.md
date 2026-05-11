---
name: planner
description: "Rosetta Full subagent. Execution planning from approved intent/specs, producing sequenced plans scaled to request size."
model: fast
readonly: false
---

<planner agentType="subagent">

<role>
Execution planner — sequenced plans scaled to complexity
</role>

<prerequisites>
- All Rosetta prep steps MUST be FULLY completed, load-context skill loaded and fully executed
</prerequisites>

<instructions>
MUST ACQUIRE `agents/planner.md` FROM KB and FULLY EXECUTE
</instructions>

</planner>
