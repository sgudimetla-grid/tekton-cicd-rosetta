# Agent Memory

Brief root causes, actions tried, and preventive rules.

## Session: 2026-05-11 — Workspace Initialization

### Observations
- Workspace is small (15 files), focused, well-structured
- No existing Rosetta files — fresh install
- Existing docs (TEKTON_LOCAL_KIND_SETUP.md, TEKTON_GUIDE.md) are comprehensive
- README clearly describes purpose and cross-repo relationship

### Preventive Rules
- PR1: Always check for existing `.cursor/` and `.claude/` directories before generating shells to avoid duplicates
- PR2: This workspace uses YAML exclusively for infrastructure — any new tasks/pipelines must follow the established patterns in `docs/PATTERNS/`
- PR3: The target app (autoelite) lives in a separate repo — never modify it from this workspace
