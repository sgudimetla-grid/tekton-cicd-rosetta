# Tech Stack

This workspace is a Tekton CI/CD pipeline repository targeting a Next.js application deployment on Kubernetes.

## Core Technologies

| Technology | Version/API | Purpose |
|-----------|-------------|---------|
| Tekton Pipelines | v1 | CI/CD pipeline orchestration |
| Tekton Triggers | v1beta1 | GitHub webhook-driven pipeline execution |
| Kubernetes | 1.29+ | Deployment target |
| Kind | latest | Local Kubernetes cluster for development |
| Docker | latest | Container runtime, local registry |
| Kaniko | v1.23.0 | In-cluster container image builds (no Docker daemon) |
| Shell/Bash | POSIX | Cluster bootstrap and task scripts |

## Build Environment

| Technology | Version | Purpose |
|-----------|---------|---------|
| Node.js | 20 (Alpine) | Next.js app build |
| npm | bundled with Node | Dependency management |
| Alpine Linux | 3.19 | Lightweight task runner base image |
| alpine/git | 2.43.0 | Git operations in-cluster |
| alpine/k8s | 1.29.4 | kubectl operations in-cluster |

## Target Application

| Technology | Version | Notes |
|-----------|---------|-------|
| Next.js | 15 | AutoElite car marketplace (separate repo) |

## Infrastructure

| Component | Details |
|-----------|---------|
| Registry | Local: kind-registry:5000 (localhost:5001 from host) |
| Cluster | Kind cluster `tekton-test` |
| Ingress | GitHub webhook via ngrok (dev) |

## Configuration Format

- YAML — all Tekton resources and Kubernetes manifests
- Markdown — documentation
- Shell scripts — cluster bootstrap
