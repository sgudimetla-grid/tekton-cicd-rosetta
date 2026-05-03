# DEPENDENCIES

Direct dependencies of this repo. Pipeline-only — no language package manifests (no `package.json`, `go.mod`, etc.). Dependencies are container images pinned in Tekton task definitions, plus cluster-side controllers installed at setup time.

## Container images (pinned in `tekton/tasks/`)

| Component | Image | Version |
|---|---|---|
| git-clone | `alpine/git` | 2.43.0 |
| nextjs-install-build | `node:<node-version>-alpine` | param-driven (default per pipeline params) |
| build-push-image | `gcr.io/kaniko-project/executor` | v1.23.0 |
| kubernetes-deploy | `alpine/k8s` | 1.29.4 |
| pipeline-status (finally) | `alpine` | 3.19 |
| local registry | `registry` | 2 |

## Cluster controllers (installed via setup walkthrough, not pinned in repo)

- Tekton Pipelines — `tekton.dev/v1`
- Tekton Triggers — `triggers.tekton.dev/v1beta1`
- Tekton Dashboard

## Local CLI tools (developer-side, see `docs/TEKTON_LOCAL_KIND_SETUP.md`)

- Docker
- kubectl
- Kind
- `tkn` (Tekton CLI)
- ngrok

## External git repository (cloned at runtime)

- `github.com/sgudimetla-grid/autoelite` — Next.js 15 car-marketplace storefront, the workload this pipeline builds and deploys. Pinned per PipelineRun via `repo-url` + `revision` params or extracted from GitHub push webhook payload.

## AI tooling

- Rosetta MCP server — `rosetta.evergreen.gcp.griddynamics.net/mcp` (R2.0 instructions)
