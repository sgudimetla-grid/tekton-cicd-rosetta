# Pattern — Tekton Task definition

## Status

Active. Used for all 5 tasks in this repo.

## Shape

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: <task-name>
  labels:
    app.kubernetes.io/part-of: nextjs-pipeline
spec:
  description: <one-line purpose>
  params:
    - name: <param>
      type: string
      default: <default-or-omitted>
      description: <what it is>
  workspaces:
    - name: <workspace-name>
      description: <what gets read/written>
  steps:
    - name: <step-name>
      image: <image>:<pinned-tag>
      workingDir: $(workspaces.<name>.path)
      script: |
        #!/usr/bin/env sh
        set -eu
        # ...
```

## Conventions

- `apiVersion: tekton.dev/v1` (stable, not v1beta1).
- Always set `metadata.labels.app.kubernetes.io/part-of: nextjs-pipeline` for grouping.
- Pinned image tag — no `latest`. `node-version` is the one parameterized exception (driven by Pipeline param).
- `set -eu` at the top of every shell `script:`.
- One-line `description:` on the Task; longer rationale belongs in repo docs, not in the YAML.
- Parameters: required ones omit `default:`; optional ones declare an explicit default.
- Workspaces named by purpose (`source`, `docker-credentials`), not by Task.
- Tasks emit `results:` only when downstream Tasks consume them (e.g., `build-image` → `image-url`).

## Anti-patterns

- Mounting Docker socket into a step (use Kaniko instead).
- Using `image: <name>:latest`.
- Inline kubectl-style YAML in `script:` blocks — generate with envsubst or use `kubernetes-deploy` Task.
