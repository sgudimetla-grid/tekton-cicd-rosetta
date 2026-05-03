# Pattern — EventListener trigger stack

## Status

Active. One stack: GitHub push → PipelineRun.

## Shape

Four files in `tekton/triggers/`:

- `event-listener.yaml` — `EventListener` (the HTTP receiver)
- `trigger-binding.yaml` — `TriggerBinding` (extracts fields from webhook payload)
- `trigger-template.yaml` — `TriggerTemplate` (renders a `PipelineRun` from bound fields)
- `rbac.yaml` — `ServiceAccount` + `Role`/`ClusterRole` + bindings (lets EventListener create PipelineRuns)

## Conventions

- `apiVersion: triggers.tekton.dev/v1beta1` for EventListener / TriggerBinding / TriggerTemplate.
- One file per resource type — do not collapse into a single multi-doc file. Easier to diff and re-apply.
- TriggerBinding extracts: `repo-url` from `body.repository.clone_url`, `revision` from `body.head_commit.id`. Manual runs override these as PipelineRun params instead of going through the binding.
- TriggerTemplate's `PipelineRun` spec must declare every workspace the Pipeline expects (shared-workspace, docker-credentials).
- RBAC: minimum viable Role + ClusterRole — EventListener SA needs `create` on `pipelineruns` in its namespace and `get/list` cluster-wide for Tekton resources.

## Webhook → run path

1. GitHub push → ngrok → EventListener service
2. EventListener applies TriggerBinding → produces `tt.params.<name>` values
3. TriggerTemplate renders a `PipelineRun` with those params
4. PipelineRun starts the standard `nextjs-build-deploy` Pipeline
