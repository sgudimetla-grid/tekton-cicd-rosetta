# Pattern: Trigger Chain

## Context

GitHub webhooks trigger pipeline runs through a chain of Tekton Triggers components.

## Flow

```
GitHub Push → EventListener → Interceptors → TriggerBinding → TriggerTemplate → PipelineRun
```

## Components

### EventListener
- Receives HTTP POST from GitHub
- References TriggerBindings and TriggerTemplates
- Applies interceptors for validation and filtering

### Interceptors (ordered)
1. **GitHub interceptor**: Validates webhook signature via shared secret
2. **CEL interceptor**: Filters to `refs/heads/main` only + extracts short SHA overlay

### TriggerBinding
- Extracts fields from GitHub JSON payload using JSONPath
- Maps: `body.repository.clone_url`, `body.after`, `body.ref`, `body.head_commit.id`, etc.

### TriggerTemplate
- Creates a PipelineRun resource from extracted params
- Uses `generateName` for unique run names
- Annotates with commit metadata for traceability

## Conventions

1. **Security**: Always validate webhook signature before processing
2. **Filtering**: Use CEL to reject irrelevant events early (non-main branches)
3. **Traceability**: Annotate PipelineRuns with commit SHA, message, pusher
4. **Labels**: Consistent `app.kubernetes.io/part-of` across all trigger resources
5. **RBAC**: Dedicated ServiceAccounts with minimal required permissions

## Anti-patterns

- Processing all branches without filtering
- Skipping webhook signature validation
- Overly broad RBAC permissions
