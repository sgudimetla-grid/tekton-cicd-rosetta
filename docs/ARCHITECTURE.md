# ARCHITECTURE

Technical architecture, modules, structure. Business context lives in [CONTEXT.md](CONTEXT.md). File-level layout in [CODEMAP.md](CODEMAP.md). Pinned versions in [TECHSTACK.md](TECHSTACK.md) and [DEPENDENCIES.md](DEPENDENCIES.md). Recurring conventions in [PATTERNS/](PATTERNS/INDEX.md).

## Top-level shape

This is a **pipeline-only** repo. It owns YAML definitions for one Tekton Pipeline plus its supporting Tasks, Triggers, and RBAC. The application source it builds (AutoElite Next.js) is cloned from an external repo at PipelineRun time.

## Cross-repo contract: AutoElite

The AutoElite repo is owned by a different team. Pipeline changes here MUST preserve the existing contract — do not require AutoElite-side changes without coordination. Contract surface:

- **Build entry point**: `package.json` at repo root with a working `npm ci` install path and `npm run build` script.
- **Image build**: a Dockerfile at the repo root, Kaniko-compatible (no Docker-only features like multi-stage `--mount=type=cache` without a fallback).
- **Runtime contract**: built image listens on whatever port the inline-generated Deployment/Service expects (currently the Pipeline owns this; if AutoElite changes its port, the `kubernetes-deploy` Task must change in lockstep).
- **Revision identity**: pipeline pins to a `revision` (commit SHA preferred) per PipelineRun — no implicit `main` tracking in production-shaped runs.

Anything beyond this surface is internal to AutoElite and is not Pipeline's concern.

## Modules

### `tekton/tasks/` — reusable Task definitions

5 Tasks total. Each is a single YAML file following the [tekton-task pattern](PATTERNS/tekton-task.md).

- `git-clone` — shallow clone of a target repo into a workspace
- `nextjs-install-build` — `npm ci` + `npm run build` against a Node alpine image (node version param-driven)
- `build-push-image` — Kaniko-based image build/push to the in-cluster registry; emits `image-url` result
- `kubernetes-deploy` — generates Deployment/Service YAML inline (env-substituted templates) and `kubectl apply`s them using `alpine/k8s`. App-side k8s/ manifests are not consumed; pipeline owns the manifest shape.
- `report-pipeline-status` — defined inline in the Pipeline file; runs in `finally`

### `tekton/pipelines/` — Pipeline definitions

One Pipeline: `nextjs-build-deploy`. Linear DAG (`clone → build-app → build-image → deploy`) plus a `finally` block for status reporting. See [PATTERNS/tekton-pipeline-composition.md](PATTERNS/tekton-pipeline-composition.md).

### `tekton/triggers/` — webhook-driven runs

Standard Tekton Triggers stack: `EventListener` + `TriggerBinding` + `TriggerTemplate` + RBAC. Receives GitHub push payloads (typically via ngrok in local setup), extracts `repo-url` and `revision`, and instantiates a PipelineRun. See [PATTERNS/tekton-trigger-stack.md](PATTERNS/tekton-trigger-stack.md).

### `setup-kind.sh` — cluster bootstrap

Shell script that creates a Kind cluster (`kind-tekton-test`), starts a local Docker registry container (`kind-registry` on port 5001), patches containerd to mirror `kind-registry:5000`, and registers the registry as a `local-registry-hosting` ConfigMap. Idempotent — safe to re-run.

### `docs/` — reference documentation

Three human-authored docs predate Rosetta init:

- `TEKTON_GUIDE.md` — tool-agnostic Tekton primer (Tasks/Pipelines/Triggers/Workspaces)
- `TEKTON_LOCAL_KIND_SETUP.md` — full local walkthrough (install → setup → trigger)
- `ROSETTA_MASTER_GUIDE.md` — Rosetta concepts, IDE setup, workflows

Rosetta-generated docs (CONTEXT, ARCHITECTURE, IMPLEMENTATION, ASSUMPTIONS, TECHSTACK, CODEMAP, DEPENDENCIES, PATTERNS) live alongside.

### `.claude/` — Claude Code shells

40 files under `.claude/` (bootstrap rule + skills + subagents + slash commands), all generated from the Rosetta KB. Each shell delegates to the central Rosetta KB via `ACQUIRE`.

### `agents/` — Rosetta orchestration tracking

- `init-workspace-flow-state.md` — phase tracking for the init workflow (transient)
- `IMPLEMENTATION.md` — current state of work (created by this phase)
- `MEMORY.md` — agent operational memory (created by this phase, starts empty)

## Data flow at runtime

1. Trigger source (manual or GitHub push via EventListener) → PipelineRun
2. PipelineRun mounts `shared-workspace` (PVC) and `docker-credentials` (Secret)
3. `git-clone` populates `shared-workspace` from the AutoElite repo at the requested revision
4. `nextjs-install-build` runs `npm` against that workspace, leaves build artifacts
5. `build-push-image` (Kaniko) reads the Dockerfile + build output, pushes to `kind-registry:5000/<image>:<tag>`, emits `image-url` result
6. `kubernetes-deploy` consumes `image-url`, applies a Deployment + Service to the deploy namespace
7. `finally → report-pipeline-status` prints terminal status

## Cluster + registry topology

- Kind cluster (`kind-tekton-test`) and the registry container (`kind-registry`) share Docker network `kind`
- Inside the cluster, images are addressed as `kind-registry:5000/...`
- From the developer host, the same registry is `localhost:5001` (`curl http://localhost:5001/v2/_catalog`)
- containerd is patched at cluster creation time to treat `localhost:5001` as a mirror

## Testing architecture

- No automated tests in this repo. Validation happens by running the pipeline end-to-end against the AutoElite app and inspecting the resulting Deployment / Service / Pod state.
- Future: integration smoke tests would belong in a separate `tests/` module driven by `tkn pipeline start` + `kubectl wait` assertions.

## Styling / conventions

- All YAML uses `tekton.dev/v1` (stable), Triggers use `triggers.tekton.dev/v1beta1`.
- All container images are pinned to exact tags (no `latest`). Node version is param-driven from the Pipeline.
- Shell `script:` blocks always start with `#!/usr/bin/env sh` + `set -eu`.
- Every Tekton resource carries `app.kubernetes.io/part-of: nextjs-pipeline` for grouping.
- One Tekton resource per file unless the Task is single-use to its Pipeline (then inline).

## Style for this file

Technical-only. Each module section answers "what is here, what does it do, what does it depend on." If you find yourself writing stakeholder rationale, it belongs in CONTEXT.md.
