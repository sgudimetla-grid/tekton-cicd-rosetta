# ASSUMPTIONS

Open assumptions and unknowns surfaced during Rosetta init. Each entry: assumption · confidence · target file when resolved.

## Active

### A1 · Single-developer / single-environment scope

- **Assumption**: This repo targets one developer running a single local Kind cluster. No multi-env promotion (dev → stage → prod), no multi-tenant pipeline reuse.
- **Confidence**: high — README, setup script, and trigger stack all assume one local cluster.
- **Resolves into**: [CONTEXT.md](CONTEXT.md) (already reflected) · revisit if the user introduces additional environments.

### A2 · AutoElite app structure — RESOLVED → contract

- **Assumption**: The Pipeline assumes the cloned AutoElite repo has a `package.json` with a working `build` script and a Dockerfile compatible with Kaniko at the repo root.
- **Confidence**: high.
- **Status**: RESOLVED 2026-05-03. AutoElite is owned by a different team — the assumption is now a hard cross-repo **contract**, documented in [ARCHITECTURE.md](ARCHITECTURE.md#cross-repo-contract-autoelite). Pipeline changes must preserve this surface or be coordinated with the AutoElite owners.

### A3 · Manifest source for kubernetes-deploy — RESOLVED

- **Resolution**: Pipeline generates Deployment/Service YAML inline (env-substituted templates). The AutoElite repo does not need to ship k8s manifests. Captured in [ARCHITECTURE.md](ARCHITECTURE.md#modules) under the `kubernetes-deploy` Task description.
- **Status**: RESOLVED 2026-05-03.

### A4 · No image signing / SBOM step today

- **Assumption**: Pipeline does not produce signed images or SBOMs. Not in scope for the local sandbox.
- **Confidence**: high.
- **Resolves into**: [docs/TODO.md](TODO.md) (when created) — likely a future enhancement.

### A5 · Modernization PRO target — open

- **Assumption**: Modernization target is **not yet locked**. Candidates: GitHub Actions, GitLab CI, Argo Workflows. Don't pre-commit to GHA-specific design choices in pipeline definitions or docs until the target is selected.
- **Confidence**: high — confirmed open during init Phase 7.
- **Resolves into**: a future Modernization PRO discovery/plan in [plans/](../plans/) once a target is chosen.

### A6 · Existing `docs/*_GUIDE.md` files are reference, not Rosetta-managed

- **Assumption**: `ROSETTA_MASTER_GUIDE.md`, `TEKTON_GUIDE.md`, `TEKTON_LOCAL_KIND_SETUP.md` were authored by the user and should be preserved verbatim. Rosetta init should not rewrite them.
- **Confidence**: high — confirmed during Phase 1 mode detection.
- **Resolves into**: [CODEMAP.md](CODEMAP.md) (already documented).

## Style

One assumption per entry. Three lines max. Mark as RESOLVED inline when the target doc absorbs the answer, then sweep periodically.
