# Architecture

Technical architecture and design decisions for the Tekton CI/CD workspace.

## High-Level Architecture

```
GitHub (autoelite repo)
    │ push event
    ▼
EventListener (webhook endpoint)
    │ validate + filter (main only)
    ▼
TriggerTemplate → PipelineRun
    │
    ▼
Pipeline: nextjs-build-deploy
    ├── git-clone (alpine/git)
    ├── nextjs-install-build (node:20-alpine)
    ├── build-push-image (kaniko)
    ├── kubernetes-deploy (alpine/k8s)
    └── finally: report-pipeline-status
    │
    ▼
Kubernetes Deployment + Service (dev namespace)
```

## Module Structure

### Tasks (`tekton/tasks/`)
Single-responsibility Tekton Tasks. Each task performs one atomic CI/CD action.

### Pipeline (`tekton/pipelines/`)
Chains tasks with explicit ordering. Includes a `finally` block for status reporting regardless of success/failure.

### Triggers (`tekton/triggers/`)
Event-driven pipeline execution. Validates GitHub signatures, filters to main branch, extracts payload data, creates PipelineRuns.

### Infrastructure (`setup-kind.sh`)
Bootstraps the local dev environment: Kind cluster + local Docker registry + network bridge.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Kaniko over Docker-in-Docker | Security: no privileged containers needed |
| Kind over Minikube | Simpler multi-node support, native containerd |
| Local registry | No external dependency for local dev |
| Alpine-based images | Minimal footprint, fast pull times |
| Tekton v1 API | Stable GA API surface |
| Single pipeline | Appropriate for single-app deployment |
| `runAfter` explicit ordering | Clear dependency chain, no implicit sequencing |

## RBAC Model

- `tekton-triggers-sa`: Receives webhooks, creates PipelineRuns
- `tekton-pipeline-sa`: Deploys to Kubernetes (ClusterRole for cross-namespace deploy)

## Workspace Strategy

Shared PVC workspace (`volumeClaimTemplate`, 1Gi) carries source code across all tasks in a PipelineRun.

## Multi-App Strategy

Pipeline is parameterized to support multiple applications. Future apps can reuse the same tasks and pipeline by varying `repo-url`, `image-name`, `app-name`, and `deploy-namespace` params.

## Testing Strategy

- Manual PipelineRuns with explicit params
- Webhook-triggered runs via ngrok (for GitHub integration testing)
- `tkn` CLI for inspection and debugging

## Observability

No pipeline monitoring or alerting is currently planned. Tekton Dashboard provides basic visibility.
