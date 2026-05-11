# Context

Business and project context for the Tekton CI/CD Rosetta workspace.

## Purpose

Provide a production-grade Tekton CI/CD pipeline that builds and deploys the AutoElite Next.js application to Kubernetes on every push to `main`.

## Target State

- Fully automated CI/CD: push to main → build → test → containerize → deploy
- Local-first development using Kind cluster with no external dependencies
- GitHub webhook integration for event-driven pipeline execution
- Kaniko-based container builds (no Docker-in-Docker)
- Parameterized pipeline supporting multiple environments

## Secondary Goal (Paused)

This repository was explored as a sandbox for Rosetta's Modernization PRO workflow (Tekton → GitHub Actions). Currently paused/exploratory — not actively migrating.

## Multi-App Future

Pipeline is intended to support multiple applications beyond AutoElite. Parameterization and task reuse patterns should accommodate this.

## Target Application

**AutoElite** — a Next.js 15 car-marketplace storefront (catalog → detail → cart → checkout). Lives in a separate repository: `github.com/sgudimetla-grid/autoelite`.

## Users

- Developer (primary): pushes code, monitors pipeline status
- Platform engineer: maintains pipeline definitions and cluster setup
- Rosetta evaluator: tests modernization workflow against this codebase

## Constraints

- Local development only (Kind cluster) — no cloud provider dependency
- No Docker-in-Docker (Kaniko used instead)
- Pipeline must handle both webhook-triggered and manual runs
- All resources consistently labeled for discoverability
