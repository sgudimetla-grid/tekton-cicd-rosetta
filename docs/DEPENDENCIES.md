# Dependencies

External tools, images, and services required by this Tekton CI/CD workspace.

## Local Development Tools

| Tool | Purpose | Install |
|------|---------|---------|
| Docker Desktop | Container runtime | docker.com |
| kubectl | Kubernetes CLI | kubernetes.io |
| Kind | Local Kubernetes clusters | kind.sigs.k8s.io |
| tkn | Tekton CLI (optional) | tekton.dev |
| ngrok | Expose webhook endpoint (optional) | ngrok.com |

## Cluster Components (Installed via kubectl)

| Component | Version | Source |
|-----------|---------|--------|
| Tekton Pipelines | latest | tekton.dev releases |
| Tekton Triggers | latest | tekton.dev releases |
| Tekton Dashboard | latest (optional) | tekton.dev releases |

## Container Images Used in Tasks

| Image | Used By | Purpose |
|-------|---------|---------|
| `alpine/git:2.43.0` | git-clone | Git repository cloning |
| `node:20-alpine` | nextjs-install-build | npm install + build |
| `gcr.io/kaniko-project/executor:v1.23.0` | build-push-image | Container image build |
| `alpine/k8s:1.29.4` | kubernetes-deploy | kubectl apply |
| `alpine:3.19` | report-pipeline-status, build-push-image | Lightweight script runner |
| `registry:2` | setup-kind.sh | Local Docker registry |

## External Repositories

| Repository | Relationship |
|------------|-------------|
| `github.com/sgudimetla-grid/autoelite` | Target app cloned at pipeline runtime |

## Kubernetes Secrets Required

| Secret | Namespace | Purpose |
|--------|-----------|---------|
| `github-webhook-secret` | default | Webhook signature validation |
| `docker-registry-credentials` | default | Registry auth (config.json) |
