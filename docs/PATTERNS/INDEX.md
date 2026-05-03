# PATTERNS — index

Reusable Tekton conventions used across this repo. Three pattern families.

| Pattern | Instances | File |
| --- | --- | --- |
| Tekton Task definition | 5 (git-clone, nextjs-install-build, build-push-image, kubernetes-deploy, report-pipeline-status) | [tekton-task.md](tekton-task.md) |
| Pipeline composition + finally | 1 (nextjs-build-deploy) | [tekton-pipeline-composition.md](tekton-pipeline-composition.md) |
| EventListener trigger stack | 1 set (event-listener + binding + template + rbac) | [tekton-trigger-stack.md](tekton-trigger-stack.md) |

Add new patterns here as they emerge. Log changes in [CHANGES.md](CHANGES.md).
