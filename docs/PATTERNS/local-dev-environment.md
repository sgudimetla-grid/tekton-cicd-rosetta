# Pattern: Local Dev Environment

## Context

The workspace uses Kind + a local Docker registry to provide a fully self-contained Kubernetes environment for pipeline development.

## Components

```
setup-kind.sh
├── Docker registry (kind-registry:5000, exposed at localhost:5001)
├── Kind cluster (tekton-test)
├── Network bridge (registry → Kind network)
└── ConfigMap (local-registry-hosting in kube-public)
```

## Conventions

1. **Registry**: Local registry runs as a Docker container connected to Kind's network
2. **Addressing**: In-cluster uses `kind-registry:5000`; host uses `localhost:5001`
3. **Idempotent**: Script checks for existing registry/network before creating
4. **Kaniko flags**: `--insecure` and `--insecure-pull` for HTTP registry (no TLS locally)
5. **Storage**: PipelineRuns use `volumeClaimTemplate` with 1Gi for workspace

## Setup Sequence

1. Start Docker registry container (if not running)
2. Create Kind cluster with containerd mirror config
3. Connect registry to Kind's Docker network
4. Register registry via ConfigMap in `kube-public`

## Anti-patterns

- Using real registries for local testing
- Requiring TLS certificates for local dev
- Hard-coding cluster names without variables
