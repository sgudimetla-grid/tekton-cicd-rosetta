# Rosetta — Concise Master Guide

> **TL;DR**
> Rosetta is a meta-prompting and context-engineering system by Grid Dynamics that feeds structured instructions (rules, skills, workflows, subagents) to AI coding agents via MCP.
> It is agent-agnostic (Cursor, Claude Code, VS Code, Codex, etc.), never sees your source code, and follows a Prepare → Research → Plan → Act lifecycle.
> Install by adding one MCP endpoint to your IDE, then say "Initialize this repository using Rosetta."
> Everything is versioned, layered (Core → Org → Project), and enforced through guardrails and human-in-the-loop gates.
> It ships 30+ skills, 11 agents, 12 workflows, and covers the full SDLC from requirements to modernization.

---

## 1. What Is Rosetta?

Rosetta is a **meta-prompting, context engineering, and centralized instructions management system** for AI coding agents, built by **Grid Dynamics**. It solves the problem of AI agents missing conventions, constraints, and business rules — leading to low-quality output and high rejection rates. Rosetta delivers structured knowledge (rules, skills, workflows) to any MCP-compatible IDE so every agent operates with full project context, without ever seeing your source code.

---

## 2. Key Concepts

| Term | One-line Definition |
|---|---|
| **Bootstrap** | Universal policies (core, execution, guardrails, HITL) loaded at agent startup |
| **Classification** | Auto-detection of request type (coding, research, init, etc.) that routes to a workflow |
| **Workflow** | Multi-phase pipeline coordinating subagents for a specific request type |
| **Skill** | Reusable unit of work loaded on demand (coding, testing, planning, debugging, etc.) |
| **Rule** | Persistent constraint applied globally or by path pattern (guardrails, best practices) |
| **Subagent** | Delegated specialist with fresh context and its own system prompt |
| **Release** | Versioned instruction set (r1, r2) enabling safe evolution and rollback |
| **HITL** | Human-in-the-loop — approval gates at critical decision points |
| **Guardrails** | Safety measures: scope limits, data protection, risk assessment, approval gates |
| **MCP** | Model Context Protocol — the transport between IDE and Rosetta server |
| **VFS** | Virtual File System — resource paths used to organize and retrieve instructions |
| **Bundler** | Merges multiple docs at the same VFS path into a single XML response |
| **P-RPA** | Prepare → Research → Plan → Act — standard lifecycle every workflow follows |

---

## 3. Supported IDEs & Agents

| IDE / Agent | Transport | Config File |
|---|---|---|
| Cursor | HTTP (OAuth) | `~/.cursor/mcp.json` or `.cursor/mcp.json` |
| Claude Code | HTTP (OAuth) | `claude mcp add` CLI |
| Codex | HTTP (OAuth) | `codex mcp add` CLI |
| VS Code / GitHub Copilot | HTTP | `.vscode/mcp.json` or `~/.mcp.json` |
| JetBrains (Copilot) | HTTP | `~/.config/github-copilot/intellij/mcp.json` |
| JetBrains (Junie) | HTTP | Settings → Tools → Junie → MCP |
| Windsurf | HTTP | Windsurf MCP config |
| Antigravity | HTTP | Antigravity MCP config (`serverUrl`) |
| OpenCode | HTTP | `opencode.json` |
| Air-gapped (any) | STDIO | Local `uvx ims-mcp` with API key |

---

## 4. Installation

### Prerequisites
- An MCP-compatible IDE (see table above)
- Recommended models: **Sonnet 4.6**, **GPT-5.3-codex-medium**, **gemini-3.1-pro** or better
- Manager/company approval to use Rosetta

### Steps

1. **Add MCP endpoint** — add to your IDE's MCP config:
```json
{
  "mcpServers": {
    "Rosetta": {
      "url": "<rosetta-mcp-server-url>"
    }
  }
}
```

2. **Authenticate** — complete OAuth flow when prompted (restart IDE if prompt doesn't appear).

3. **Verify** — ask the agent:
```
What can you do, Rosetta?
```

4. **Initialize** (once per repo):
```
Initialize this repository using Rosetta
```

5. **(Optional) Add bootstrap rule** — download `bootstrap.md` from GitHub and place in IDE-specific location:

| IDE | Destination |
|---|---|
| Cursor | `.cursor/rules/bootstrap.mdc` |
| Claude Code | `.claude/claude.md` |
| VS Code / Copilot | `.github/copilot-instructions.md` |
| Windsurf | `.windsurf/rules/bootstrap.md` |
| OpenCode | `AGENTS.md` |

---

## 5. Quick Start

### CLI Example (STDIO mode for local dev)

```bash
# Install CLI
uvx rosetta-cli@latest verify

# Publish instructions to server
cp rosetta-cli/.env.dev .env
uvx rosetta-cli@latest publish instructions

# Dry-run preview
uvx rosetta-cli@latest publish instructions --dry-run
```

### IDE Example (typical session)

```
You:    "Add password reset functionality"

Rosetta:
  1. Loads coding workflow
  2. Reads CONTEXT.md and ARCHITECTURE.md
  3. Discovers existing auth code
  4. Creates tech spec in plans/PASSWORD-RESET/
  5. Waits for your approval          ← HITL gate
  6. Implements the feature
  7. Reviewer inspects the code
  8. Writes tests (80%+ coverage)
  9. Validator verifies against specs
```

---

## 6. Core Features

### Workflows (12 total)

| Workflow | Purpose |
|---|---|
| **Init Workspace** | Generate TECHSTACK.md, CODEMAP.md, ARCHITECTURE.md, CONTEXT.md for a repo |
| **Coding** | Full implementation: specs → plan → approve → code → review → test → validate |
| **Requirements Authoring** | Atomic requirements in EARS format with traceability matrix |
| **Research PRO** | Systematic investigation with grounded references |
| **Code Analysis** | Reverse-engineer architecture docs from existing codebase |
| **Automated QA PRO** | Create/update UI tests from TestRail cases |
| **Test Case Generation PRO** | Generate TestRail-ready test cases from Jira/Confluence |
| **Modernization PRO** | Large migrations (Java 8→21, monolith→microservices, .NET upgrades) |
| **External Library PRO** | Onboard external/private codebases for AI agent use |
| **Coding Agents Prompting PRO** | Author/adapt prompts for AI coding agents |
| **Ad-hoc** | Custom workflow when no fixed workflow fits |
| **Self Help** | Discover Rosetta capabilities and get guidance |

### Skills (30+)

Coding, Testing, Tech Specs, Planning, Reasoning, Questioning, Debugging, Load Context, Reverse Engineering, Requirements Authoring, Large Workspace Handling, Code Review PRO, Security PRO, Research PRO, Discovery PRO, Git PRO, Natural Writing PRO, and more.

### Subagents (11)

Discoverer, Executor, Planner, Architect, Engineer, Reviewer, Validator, Analyst PRO, Orchestrator PRO, Researcher PRO, Prompt Engineer PRO.

### Always-Active Protections

| Rule | Effect |
|---|---|
| Approval before action | Plan shown; waits for explicit approval |
| No data deletion | Never deletes server data or generates deletion scripts |
| Sensitive data protection | PII/financial data masked, never logged |
| Bounded scope | Max ~2 hours work, 15 files, spec files <350 lines |
| Risk assessment | Dangerous tools (DB, cloud, S3) get risk levels; critical = blocked |
| Context monitoring | Warns at 65% context usage, escalates at 75% |

---

## 7. Common Use Cases

### Use Case 1: Repository Onboarding
```
You:    "Initialize this repository using Rosetta"

Output: Generates docs/TECHSTACK.md, docs/CODEMAP.md, docs/DEPENDENCIES.md,
        docs/CONTEXT.md, docs/ARCHITECTURE.md, agents/IMPLEMENTATION.md
        Asks clarifying questions, verifies completeness.
```

### Use Case 2: Feature Implementation with Guardrails
```
You:    "Implement the notification service"

Output: Discovery → Tech Spec → Plan Review (HITL) → Implementation →
        Code Review → Validation → Test Generation → Final Validation
        All artifacts in plans/NOTIFICATION-SERVICE/
```

### Use Case 3: Large-Scale Modernization
```
You:    "Migrate from Java 8 to Java 21"

Output: Analyze legacy code → Document behavior → Map target design →
        Approval gate → Implement per-project from approved specs →
        Validate behavior preservation
        Specs in docs/original-code-specs-*.md, docs/target-code-specs-*.md
```

---

## 8. Configuration Essentials

### Key Environment Variables

| Variable | Purpose | Required |
|---|---|---|
| `ROSETTA_SERVER_URL` | RAGFlow backend URL | Yes |
| `ROSETTA_API_KEY` | RAGFlow API key (dataset owner) | Yes |
| `REDIS_URL` | Session store for MCP | Yes (HTTP) |
| `ROSETTA_TRANSPORT` | `http` or `stdio` | No (default: http) |
| `ROSETTA_MODE` | `HARD` (strict) or `SOFT` (lighter) | No (default: HARD) |
| `VERSION` | Instruction release (`r1`, `r2`) | No (server-controlled) |
| `INSTRUCTION_ROOT_FILTER` | Layers to include (e.g., `CORE,GRID`) | No |
| `IMS_DEBUG` | Debug logging (`1` = on) | No |
| `ROSETTA_OAUTH_MODE` | `oauth`, `oidc`, or `github` | No (default: oauth) |
| `ROSETTA_JWT_SIGNING_KEY` | JWT token signing secret | Yes (prod) |
| `FERNET_KEY` | Encrypts OAuth tokens in Redis | Yes (prod) |

### Deployment Modes

| Mode | RAGFlow | Rosetta MCP | Best for |
|---|---|---|---|
| Hosted | Cloud Kubernetes | Cloud Kubernetes (HTTP) | Teams, production |
| Local | Docker Compose | Docker Compose or STDIO | Development, evaluation |
| Air-gapped | Docker Compose (offline) | STDIO (offline instructions) | Regulated environments |

---

## 9. Limitations & Gotchas

- **Not a code executor** — Rosetta guides agents; agents modify code
- **No real-time monitoring** — no continuous observation during agent execution
- **Not a project manager** — no scheduling, assignment, or progress tracking
- **SDLC only** — guardrails block non-development requests
- **Model-sensitive** — avoid "Auto" model selection; weak models skip tool calls and hallucinate
- **OAuth tokens expire silently** — MCP degrades without re-authentication; tools appear but instructions stop loading
- **Sticky sessions required** — when scaling MCP to multiple replicas, each client must hit the same pod
- **Full-folder publishing only** — never publish subfolders or single files (breaks tag extraction)
- **Single API key owns all datasets** — `ROSETTA_API_KEY` must belong to the dataset owner; high-value secret
- **Context limits** — context monitoring warns at 65% and escalates at 75%; large repos need init per sub-repo
- **Composite workspaces** — init each repository separately, then init at workspace level

---

## 10. Cheat Sheet

| # | Action | Command / Prompt |
|---|---|---|
| 1 | **Connect MCP** | Add `{"mcpServers":{"Rosetta":{"url":"<URL>"}}}` to IDE config |
| 2 | **Verify connection** | `"What can you do, Rosetta?"` |
| 3 | **Initialize repo** | `"Initialize this repository using Rosetta"` |
| 4 | **Implement feature** | `"Add password reset functionality"` |
| 5 | **Run research** | `"Research best practices for microservices auth"` |
| 6 | **Analyze codebase** | `"Explain how the authentication system works"` |
| 7 | **Write requirements** | `"Define requirements for the checkout flow"` |
| 8 | **Publish instructions** | `uvx rosetta-cli@latest publish instructions` |
| 9 | **Dry-run publish** | `uvx rosetta-cli@latest publish instructions --dry-run` |
| 10 | **Force republish** | `uvx rosetta-cli@latest publish instructions --force` |

### MCP Tool Reference

| Tool | Purpose |
|---|---|
| `get_context_instructions` | Bootstrap: load all rules and guardrails |
| `query_instructions` | Fetch docs by tags (primary) or keyword search (fallback) |
| `list_instructions` | Browse VFS hierarchy |
| `query_project_context` | Search project-specific docs (opt-in) |
| `store_project_context` | Create/update a doc in project dataset (opt-in) |
| `plan_manager` | Manage execution plans with phases and status (opt-in) |
| `submit_feedback` | Auto-submit structured session feedback |

### Command Aliases (used inside instructions)

| Alias | Action |
|---|---|
| `GET PREP STEPS` | Load bootstrap rules |
| `ACQUIRE <path> FROM KB` | Fetch by tags |
| `SEARCH <query> IN KB` | Keyword search |
| `LIST <path> IN KB` | Browse folder |
| `USE SKILL <name>` | Load a skill |
| `INVOKE SUBAGENT <name>` | Call a subagent |
| `USE FLOW <name>` | Activate a workflow |

---

*Source: [griddynamics.github.io/rosetta/docs](https://griddynamics.github.io/rosetta/docs/) · [github.com/griddynamics/rosetta](https://github.com/griddynamics/rosetta)*
