# Pattern: Tekton Task Structure

## Context

All Tekton Tasks in this workspace follow a consistent structure for maintainability and reuse.

## Structure

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: <verb>-<noun>
  labels:
    app.kubernetes.io/part-of: nextjs-pipeline
spec:
  description: <one-line purpose>
  params:
    - name: <param>
      type: string
      default: <sensible-default>  # optional
      description: <what it controls>
  workspaces:
    - name: source
      description: <workspace purpose>
  results:
    - name: <output-name>
      description: <what gets emitted>
  steps:
    - name: <step-verb>
      image: <minimal-alpine-based-image>:<pinned-version>
      workingDir: $(workspaces.source.path)
      script: |
        #!/usr/bin/env sh
        set -eu
        <logic>
```

## Conventions

1. **Naming**: `<verb>-<noun>` (e.g., `git-clone`, `build-push-image`)
2. **Images**: Alpine-based, version-pinned (e.g., `alpine/git:2.43.0`)
3. **Scripts**: Always start with `#!/usr/bin/env sh` and `set -eu`
4. **Labels**: All resources carry `app.kubernetes.io/part-of: nextjs-pipeline`
5. **Params**: Typed as `string`, include sensible defaults where possible
6. **Results**: Used to pass data between tasks (e.g., `image-url`, `build-status`)

## Anti-patterns

- Using `latest` tags for task images
- Multi-purpose tasks (violates single responsibility)
- Hard-coded values instead of params
