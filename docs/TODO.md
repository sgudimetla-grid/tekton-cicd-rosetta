# TODO

Improvements, suggestions, and larger pieces of work that aren't immediately scheduled. Distinct from [ASSUMPTIONS.md](ASSUMPTIONS.md) (which tracks unknowns) and [agents/IMPLEMENTATION.md](../agents/IMPLEMENTATION.md) (which tracks current state).

## High value

- **Modernization PRO discovery**: pick a target (GHA / GitLab CI / Argo Workflows) for the eventual Tekton migration. See [ASSUMPTIONS A5](ASSUMPTIONS.md#a5--modernization-pro-target--open).
- **Pipeline integration smoke test**: a `tkn pipeline start` → `kubectl wait` script that runs the whole flow against AutoElite and asserts on the Deployment becoming Ready. None today.

## Medium value

- **Image signing / SBOM**: not in scope for the local sandbox, but a likely future enhancement (cosign + syft, or equivalent on whatever target platform). See [ASSUMPTIONS A4](ASSUMPTIONS.md#a4--no-image-signing--sbom-step-today).
- **Document the secrets pattern**: how `docker-credentials` workspace is populated locally vs. how it would work in a hosted target.

## Low value / nice-to-have

- Fan-out for parallel tasks (e.g., lint + test + build in parallel before image build). Today's DAG is strictly linear.
- Dashboard wiring docs — current setup installs Tekton Dashboard but doesn't document an opinionated way to use it.

## Style

One bullet per item. Move resolved items out of this file (don't strike-through). Anything actively in progress belongs in [agents/IMPLEMENTATION.md](../agents/IMPLEMENTATION.md), not here.
