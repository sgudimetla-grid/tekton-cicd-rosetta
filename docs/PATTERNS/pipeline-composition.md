# Pattern: Pipeline Composition

## Context

The pipeline chains Tasks sequentially with explicit ordering and a `finally` block for status reporting.

## Structure

```yaml
apiVersion: tekton.dev/v1
kind: Pipeline
spec:
  params: [...]       # Parameterize everything configurable
  workspaces: [...]   # Shared storage between tasks
  tasks:
    - name: <step>
      taskRef:
        name: <task-name>
      runAfter: [<previous>]   # Explicit ordering
      params: [...]
      workspaces: [...]
  finally:
    - name: report-status
      taskRef:
        name: report-pipeline-status
```

## Conventions

1. **Sequential chaining**: `runAfter` declares explicit dependencies
2. **Data passing**: Results from one task feed params of the next via `$(tasks.<name>.results.<result>)`
3. **Finally block**: Always runs regardless of success/failure — used for cleanup/reporting
4. **Workspaces**: Shared PVC workspace (`shared-workspace`) carries source code across tasks
5. **Parameterization**: Pipeline-level params cascaded down to tasks — no hard-coded values

## Data Flow

```
Pipeline params → task params → step scripts
Task results → downstream task params
```

## Anti-patterns

- Implicit task ordering (relying on declaration order)
- Skipping finally block (no visibility into failures)
- Monolithic single-task pipelines
