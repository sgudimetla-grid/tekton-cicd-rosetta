# TECHSTACK

Tech stack and key stack decisions for the Tekton CI/CD pipeline that builds and deploys the AutoElite Next.js app to a local Kind Kubernetes cluster.

## CI/CD orchestration

- **Tekton Pipelines** — `tekton.dev/v1` (Tasks, Pipelines, PipelineRuns)
- **Tekton Triggers** — `triggers.tekton.dev/v1beta1` (EventListener, TriggerBinding, TriggerTemplate)
- **Tekton Dashboard** — installed alongside per setup docs

## Runtime / cluster

- **Kubernetes** — local Kind cluster (`kind-tekton-test`), node image per Kind defaults
- **Container runtime** — containerd (patched for `kind-registry:5000` mirror)
- **Local image registry** — Docker `registry:2` exposed at `localhost:5001`, accessed in-cluster as `kind-registry:5000`

## Pipeline tooling (container images pinned)

| Stage | Image | Purpose |
|---|---|---|
| Clone | `alpine/git:2.43.0` | git checkout step |
| Build | `node:<param>-alpine` | npm install + Next.js build (node version param-driven) |
| Image build | `gcr.io/kaniko-project/executor:v1.23.0` | rootless container image build/push |
| Deploy | `alpine/k8s:1.29.4` | kubectl apply for k8s manifests |
| Status | `alpine:3.19` | finally-block status reporting |

## Target workload

- **AutoElite** — Next.js 15 car-marketplace storefront, lives in separate repo `sgudimetla-grid/autoelite`. This repo only contains pipeline definitions; the app source is cloned at PipelineRun time.

## Local dev tooling (per setup docs)

- Docker (Desktop or engine)
- kubectl
- Kind
- `tkn` (Tekton CLI)
- ngrok (for exposing EventListener to GitHub webhooks)

## Languages / formats

- **YAML** — all pipeline/task/trigger definitions (Tekton CRDs)
- **Bash** — `setup-kind.sh` (Kind cluster + registry bootstrap)
- **Markdown** — project documentation only

## AI-agent tooling

- **Rosetta MCP** (R2.0) — `https://rosetta.evergreen.gcp.griddynamics.net/mcp` — meta-prompting / context engineering for Claude Code
- **Claude Code** — primary AI coding agent; shells under `.claude/`

## Key stack decisions

- **Pipeline-only repo** — application code (AutoElite) lives elsewhere; pipeline clones it at runtime via `repo-url` and `revision` params (manual) or extracted from GitHub push payload (webhook-driven).
- **Local-first** — entire pipeline runs end-to-end on a Kind cluster + local Docker registry; no cloud dependencies for the demo path.
- **Kaniko for image builds** — daemonless, in-cluster, no Docker socket mount.
- **Pinned image versions** — every pipeline image is pinned to an exact tag (no `latest`).
- **Rosetta sandbox** — repo also serves as the Modernization PRO target for evaluating Tekton → GitHub Actions migration.
