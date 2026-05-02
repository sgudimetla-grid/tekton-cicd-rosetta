# Tekton CI/CD

Tekton pipeline that builds and deploys the **AutoElite** Next.js app to a Kubernetes cluster on every push to `main`. Runs end-to-end on a local Kind cluster with a local Docker registry.

> **AutoElite** is a small Next.js 15 car-marketplace storefront (catalog → detail → cart → checkout) that lives in a separate [`autoelite`](https://github.com/sgudimetla-grid/autoelite) repo. It's the test workload this pipeline targets.

## What's in here

```
tekton/
├── tasks/         git-clone, install/build, Kaniko image build, k8s deploy, status
├── pipelines/     nextjs-build-deploy (chains the tasks + finally block)
└── triggers/      EventListener + bindings + template + RBAC
setup-kind.sh      Bootstraps a Kind cluster + local Docker registry
docs/              Tekton + Rosetta documentation
```

## Quick start

Run the full local setup walkthrough in [docs/TEKTON_LOCAL_KIND_SETUP.md](docs/TEKTON_LOCAL_KIND_SETUP.md). It covers:

1. Installing tools (Docker, kubectl, Kind, tkn, ngrok)
2. Creating the Kind cluster + local registry (`setup-kind.sh`)
3. Patching containerd so pods can pull from `kind-registry:5000`
4. Installing Tekton Pipelines, Triggers, Dashboard
5. Creating namespace, secrets, RBAC
6. Applying tasks, pipeline, triggers
7. Triggering the pipeline (manual / curl / ngrok+GitHub)
8. Validating the deployed app

For a tool-agnostic Tekton primer (Tasks, Pipelines, Triggers, Workspaces) see [docs/TEKTON_GUIDE.md](docs/TEKTON_GUIDE.md).

## Cross-repo: where the app lives

The pipeline clones the [`autoelite`](https://github.com/sgudimetla-grid/autoelite) repo at runtime. Each PipelineRun pins to a specific revision:

- **Webhook-driven runs** — the EventListener extracts the clone URL and commit SHA from GitHub's push payload at runtime. No edits needed; just point the GitHub webhook at your fork.
- **Manual runs** — pass `repo-url` and `revision` as parameters when you create the PipelineRun (the doc walkthrough does this for you).

If you fork AutoElite under a different account, substitute that URL anywhere this repo says `sgudimetla-grid/autoelite.git` (mainly the example PipelineRuns in [docs/TEKTON_LOCAL_KIND_SETUP.md](docs/TEKTON_LOCAL_KIND_SETUP.md)).

## Image registry

Inside the cluster all images use `kind-registry:5000/<image>:<tag>`. From your terminal you browse the same registry at `http://localhost:5001` (e.g., `curl http://localhost:5001/v2/_catalog`).

## Rosetta

This repo is also a sandbox for evaluating Rosetta's Modernization PRO workflow to migrate these Tekton pipelines to GitHub Actions. See [docs/ROSETTA_MASTER_GUIDE.md](docs/ROSETTA_MASTER_GUIDE.md) for the consolidated Rosetta reference.
