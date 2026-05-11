# Code Map

This workspace contains a Tekton CI/CD pipeline for building and deploying a Next.js application to Kubernetes.

## Directory Structure

```
tekton-cicd-rosetta/
├── tekton/
│   ├── tasks/                    # Tekton Task definitions
│   │   ├── git-clone.yaml        # Clone Git repository
│   │   ├── nextjs-install-build.yaml  # npm install + build
│   │   ├── build-push-image.yaml # Kaniko container image build
│   │   └── kubernetes-deploy.yaml # kubectl apply deployment + service
│   ├── pipelines/
│   │   └── nextjs-build-deploy.yaml  # Pipeline + report-status finally task
│   └── triggers/
│       ├── event-listener.yaml   # GitHub push EventListener
│       ├── trigger-binding.yaml  # Extract params from GitHub payload
│       ├── trigger-template.yaml # PipelineRun template
│       └── rbac.yaml             # ServiceAccounts, Roles, Bindings
├── docs/
│   ├── TEKTON_LOCAL_KIND_SETUP.md # Full local setup walkthrough
│   ├── TEKTON_GUIDE.md           # Tekton concepts primer
│   └── ROSETTA_MASTER_GUIDE.md   # Rosetta evaluation reference
├── agents/                       # Rosetta agent state (transient)
├── setup-kind.sh                 # Kind cluster + local registry bootstrap
├── README.md                     # Project overview
└── .gitignore
```

## Pipeline Flow

```
git-clone → nextjs-install-build → build-push-image → kubernetes-deploy
                                                              ↓
                                              finally: report-pipeline-status
```

## Key Entry Points

| File | Role |
|------|------|
| `setup-kind.sh` | Bootstrap local dev environment |
| `tekton/pipelines/nextjs-build-deploy.yaml` | Main pipeline definition |
| `tekton/triggers/event-listener.yaml` | Webhook entry point |

## Naming Conventions

- All resources labeled `app.kubernetes.io/part-of: nextjs-pipeline`
- Tasks named by action: `git-clone`, `nextjs-install-build`, `build-push-image`, `kubernetes-deploy`
- Triggers prefixed by event source: `github-push-*`
