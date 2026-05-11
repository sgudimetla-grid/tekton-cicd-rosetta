# Assumptions

Assumptions and unknowns identified during workspace analysis.

## Confirmed Assumptions

| # | Assumption | Basis |
|---|-----------|-------|
| A1 | Target app (AutoElite) has a valid Dockerfile at repo root | Pipeline uses default `Dockerfile` path |
| A2 | Node 20 is the correct build version | Explicitly set as param default |
| A3 | App listens on port 3000 | kubernetes-deploy uses 3000 as containerPort |
| A4 | `main` is the deployment branch | CEL filter checks `refs/heads/main` |
| A5 | Local dev only — no production cluster targeted | Kind-based, `--insecure` flags |

## Resolved

| # | Question | Answer | Date |
|---|----------|--------|------|
| U2 | Is the Rosetta modernization (Tekton→GitHub Actions) still active? | Paused / exploratory only | 2026-05-11 |
| U3 | Are there additional apps beyond AutoElite? | Yes — multiple apps planned | 2026-05-11 |
| U4 | What monitoring/alerting for pipeline failures? | No observability planned currently | 2026-05-11 |

## Unknowns

| # | Unknown | Impact | Resolution |
|---|---------|--------|------------|
| U1 | Will this pipeline be extended to support production deployments? | Architecture: registry, TLS, multi-env params | Marked as assumption (unsure) |
