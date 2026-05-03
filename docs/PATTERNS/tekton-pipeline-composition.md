# Pattern — Pipeline composition with finally

## Status

Active. Used by `nextjs-build-deploy`.

## Shape

```yaml
apiVersion: tekton.dev/v1
kind: Pipeline
spec:
  params:        # all Pipeline-level inputs collected here
  workspaces:    # shared-workspace + docker-credentials
  tasks:
    - name: clone        # no runAfter
    - name: build-app    # runAfter: [clone]
    - name: build-image  # runAfter: [build-app]
    - name: deploy       # runAfter: [build-image], consumes build-image results
  finally:
    - name: report-status   # always runs, consumes results from main tasks
```

## Conventions

- Linear DAG: each Task has a single `runAfter`. No fan-out today.
- Inputs flow through Pipeline params → Task params (`value: $(params.<name>)`).
- Cross-Task data flows via `$(tasks.<task>.results.<result>)` — only `build-image` produces a consumed result (`image-url`).
- `finally:` block reports terminal status using `$(tasks.<task>.results.build-status)` — runs regardless of upstream success/failure.
- Workspaces are declared on the Pipeline once and bound per Task by name.
- Inline Task definitions are allowed in the same file (e.g., `report-pipeline-status` lives in `pipelines/nextjs-build-deploy.yaml` rather than `tasks/`) when the Task is single-use to that Pipeline.

## When to extract a Task

- Reused across pipelines → move to `tekton/tasks/<name>.yaml`.
- Pipeline-specific (only ever runs in this finally block) → keep inline.
