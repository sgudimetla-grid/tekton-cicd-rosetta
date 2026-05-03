# CONTEXT

Business and domain context for this repository — stakeholder perspective, no technical detail (see [ARCHITECTURE.md](ARCHITECTURE.md) for that).

## Purpose

- Provide a working, end-to-end Tekton CI/CD pipeline that builds and deploys a Next.js application (the AutoElite car-marketplace storefront) to a local Kubernetes cluster.
- Serve as a **reference implementation and sandbox** for evaluating Grid Dynamics' Rosetta Modernization PRO workflow. Target platform for the migration is **still under evaluation** — candidates include GitHub Actions, GitLab CI, and Argo Workflows. Modernization plans should not assume GHA until a target is locked.

## Stakeholders

- **Primary user / author**: Grid Dynamics engineer evaluating Rosetta and demonstrating local Tekton workflows.
- **Audience**: personal sandbox — no other readers expected. Docs are written for the author's future self, not external consumers.

## Domain scope

- CI/CD orchestration on Kubernetes
- Local-first developer experience (no cloud account required to run end-to-end)
- AI-agent-assisted modernization (Tekton → GitHub Actions migration target)

## What's in scope here

- Tekton Task / Pipeline / Trigger definitions
- Local Kind cluster bootstrap (`setup-kind.sh`) and the local Docker registry pattern
- Reference docs walking through setup, manual runs, and webhook-driven runs
- Rosetta workspace metadata (`.claude/`, `agents/`, `docs/CONTEXT.md`, etc.)

## What's explicitly out of scope

- The application source (AutoElite Next.js app) — lives in a separate repo (`sgudimetla-grid/autoelite`) and is cloned at PipelineRun time.
- Production cluster operations — this repo targets local Kind only; productionization is out of scope.
- Multi-environment promotion, secrets management beyond the local pattern, observability stack.

## Why this exists in its current form

- Grid Dynamics is evaluating Rosetta as a centralized AI-instruction system. A small but realistic CI/CD workload makes a good test bed for the **Modernization PRO** workflow (Tekton → GHA).
- A local Kind setup keeps the demo reproducible without cloud cost or access concerns.

## Cross-references

- Architecture and modules → [ARCHITECTURE.md](ARCHITECTURE.md)
- Current state and pending work → [agents/IMPLEMENTATION.md](../agents/IMPLEMENTATION.md)
- Open assumptions → [ASSUMPTIONS.md](ASSUMPTIONS.md)
- Tech stack and dependencies → [TECHSTACK.md](TECHSTACK.md), [DEPENDENCIES.md](DEPENDENCIES.md)

## Style for this file

- Bulleted, business-only. No code, no YAML, no version numbers. If you find yourself writing implementation detail, it belongs in ARCHITECTURE.md.
