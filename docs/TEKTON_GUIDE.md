# Tekton CI/CD Guide

A practical guide for setting up and using Tekton pipelines in this repository.

## 1. What is Tekton

Tekton is a Kubernetes-native CI/CD framework. Instead of running pipelines on a separate CI server (like Jenkins), Tekton runs pipeline steps as containers inside your Kubernetes cluster.

Key difference from tools like GitHub Actions or Jenkins:
- Tekton pipelines are Kubernetes custom resources (YAML files).
- Every step runs as a container pod in your cluster.
- You need a running Kubernetes cluster to use Tekton.

## 2. Core concepts

### Task

A Task is a sequence of steps. Each step is a container that runs a command.

Think of it like a single job in GitHub Actions.

```
Task: nextjs-install-build
  Step 1: install dependencies (node container)
  Step 2: lint (node container)
  Step 3: build (node container)
```

Tasks have:
- **params**: inputs you pass in (like function arguments).
- **workspaces**: shared storage volumes between steps and tasks.
- **results**: outputs that other tasks can consume.
- **steps**: the actual container commands that run sequentially.

### Pipeline

A Pipeline chains multiple Tasks together in order.

```
Pipeline: nextjs-build-deploy
  Task 1: git-clone
  Task 2: nextjs-install-build (runs after clone)
  Task 3: build-push-image (runs after build)
  Task 4: kubernetes-deploy (runs after image push)
```

Pipelines have:
- **params**: inputs passed down to tasks.
- **workspaces**: shared volumes across tasks.
- **tasks**: ordered list of task references with `runAfter` dependencies.
- **finally**: tasks that always run at the end (like cleanup or status reporting).

### PipelineRun

A PipelineRun is a single execution of a Pipeline with specific parameter values.
In our setup, PipelineRuns are created automatically by Triggers (not manually).

### Triggers (event-driven execution)

Triggers make pipelines run automatically when something happens (like a git push).

Three components work together:
- **EventListener**: a Kubernetes service that receives incoming webhooks.
- **TriggerBinding**: extracts data fields from the webhook payload (repo URL, commit SHA, etc.).
- **TriggerTemplate**: creates a PipelineRun using the extracted data.

```
GitHub push webhook
  -> EventListener (receives HTTP request)
  -> TriggerBinding (extracts repo URL, commit SHA, branch)
  -> TriggerTemplate (creates a PipelineRun with those values)
  -> Pipeline runs automatically
```

### Interceptors

Interceptors are filters on the EventListener that validate or filter events before a pipeline runs:
- **GitHub interceptor**: validates the webhook secret to ensure the request is genuine.
- **CEL interceptor**: filters events using expressions (e.g., only trigger on `main` branch pushes).

### Workspaces

Workspaces are shared storage volumes. They let tasks pass files to each other.
For example, `git-clone` writes source code to a workspace, and `nextjs-install-build` reads from the same workspace.

Workspace types:
- **volumeClaimTemplate**: creates a fresh PVC for each run (common for source code).
- **persistentVolumeClaim**: reuses an existing PVC across runs (good for caches that persist).
- **secret**: mounts a Kubernetes secret as files (used for Docker registry credentials).

## 3. Prerequisites

You need:
1. A running Kubernetes cluster (minikube, kind, EKS, GKE, or any k8s cluster).
2. `kubectl` configured and connected to your cluster.
3. Cluster admin access (to install CRDs).

## 4. Install Tekton

### 4.1 Install Tekton Pipelines

```bash
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

Verify installation:

```bash
kubectl get pods -n tekton-pipelines
```

Wait until all pods show `Running`:

```
NAME                                           READY   STATUS
tekton-pipelines-controller-xxxxx              1/1     Running
tekton-pipelines-webhook-xxxxx                 1/1     Running
```

### 4.2 Install Tekton Triggers

Triggers are a separate component that enables event-driven pipeline execution.

```bash
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
```

Verify:

```bash
kubectl get pods -n tekton-pipelines
```

Additional pods should appear:

```
tekton-triggers-controller-xxxxx               1/1     Running
tekton-triggers-webhook-xxxxx                  1/1     Running
tekton-triggers-core-interceptors-xxxxx        1/1     Running
```

### 4.3 Install Tekton Dashboard (optional but recommended)

Provides a web UI to view pipeline runs, logs, and status.

```bash
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
```

Access it:

```bash
kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097
```

Open http://localhost:9097 in your browser.

### 4.4 Install Tekton CLI (optional)

The `tkn` CLI lets you interact with Tekton from your terminal.

macOS:

```bash
brew install tektoncd-cli
```

Linux:

```bash
curl -LO https://github.com/tektoncd/cli/releases/latest/download/tkn_Linux_x86_64.tar.gz
tar xvzf tkn_Linux_x86_64.tar.gz -C /usr/local/bin tkn
```

Verify:

```bash
tkn version
```

## 5. Set up this project's pipeline

### 5.1 Create prerequisites

Create the namespace for deployment:

```bash
kubectl create namespace dev
```

Create Docker registry credentials (for pushing images to your registry):

```bash
kubectl create secret generic docker-registry-credentials \
  --from-file=config.json=$HOME/.docker/config.json
```

Or if you use a specific registry like GHCR:

```bash
kubectl create secret docker-registry docker-registry-credentials \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_PAT \
  --docker-email=YOUR_EMAIL
```

Create the GitHub webhook secret (used by EventListener to validate incoming webhooks):

```bash
kubectl create secret generic github-webhook-secret \
  --from-literal=webhook-secret=YOUR_WEBHOOK_SECRET_HERE
```

### 5.2 Apply RBAC (service accounts and permissions)

```bash
kubectl apply -f tekton/triggers/rbac.yaml
```

This creates:
- `tekton-triggers-sa`: service account for the EventListener.
- `tekton-pipeline-sa`: service account for pipeline tasks (with permissions to deploy to k8s).

### 5.3 Apply Tasks

```bash
kubectl apply -f tekton/tasks/
```

Verify:

```bash
tkn task list
```

Expected output:

```
NAME                    AGE
git-clone               just now
nextjs-install-build    just now
build-push-image        just now
kubernetes-deploy       just now
```

### 5.4 Apply Pipeline

```bash
kubectl apply -f tekton/pipelines/
```

Verify:

```bash
tkn pipeline list
```

Expected output:

```
NAME                   AGE
nextjs-build-deploy    just now
```

### 5.5 Apply Triggers

```bash
kubectl apply -f tekton/triggers/trigger-binding.yaml
kubectl apply -f tekton/triggers/trigger-template.yaml
kubectl apply -f tekton/triggers/event-listener.yaml
```

Or all at once:

```bash
kubectl apply -f tekton/triggers/
```

Verify the EventListener created a service:

```bash
kubectl get eventlistener
kubectl get svc -l eventlistener=github-push-listener
```

Expected output:

```
NAME                    AGE
github-push-listener    just now

NAME                              TYPE        PORT(S)
el-github-push-listener           ClusterIP   8080/TCP
```

The EventListener service name follows the pattern `el-<eventlistener-name>`.

## 6. Connect GitHub webhook

### 6.1 Expose the EventListener

The EventListener needs to be reachable from GitHub. Options:

**Option A: Port-forward for local testing**

```bash
kubectl port-forward svc/el-github-push-listener 8080:8080
```

Then use a tunnel tool like ngrok:

```bash
ngrok http 8080
```

This gives you a public URL like `https://abc123.ngrok.io`.

**Option B: Ingress for production**

Create an Ingress resource pointing to `el-github-push-listener` on port 8080.

**Option C: LoadBalancer service**

```bash
kubectl patch svc el-github-push-listener -p '{"spec":{"type":"LoadBalancer"}}'
```

### 6.2 Create the webhook in GitHub

1. Go to your GitHub repo -> Settings -> Webhooks -> Add webhook.
2. **Payload URL**: `https://YOUR_PUBLIC_URL` (from step above).
3. **Content type**: `application/json`.
4. **Secret**: the same value you used in `github-webhook-secret`.
5. **Events**: select "Just the push event".
6. Click "Add webhook".

### 6.3 Test it

Push a commit to the `main` branch. Then check:

```bash
tkn pipelinerun list
```

You should see a new PipelineRun created automatically:

```
NAME                      STARTED        DURATION   STATUS
nextjs-push-xxxxx         just now       ---        Running
```

Watch logs in real time:

```bash
tkn pipelinerun logs nextjs-push-xxxxx -f
```

Or check in the Tekton Dashboard at http://localhost:9097.

## 7. What happens when you push to main

```
1. You push code to the main branch on GitHub

2. GitHub sends a POST webhook to the EventListener service

3. GitHub interceptor validates the webhook secret
   (rejects requests with wrong/missing secret)

4. CEL interceptor checks: is this a push to refs/heads/main?
   (ignores pushes to other branches)

5. TriggerBinding extracts from the webhook payload:
   - repository clone URL
   - commit SHA
   - branch ref
   - commit message
   - pusher name

6. TriggerTemplate creates a PipelineRun with those values:
   - repo-url = extracted clone URL
   - revision = commit SHA
   - image-tag = commit SHA (for unique, traceable images)

7. Pipeline executes:
   a. git-clone: clones the repo at the specific commit
   b. nextjs-install-build: npm install, lint, npm run build
   c. build-push-image: builds Docker image with Kaniko, pushes to registry
   d. kubernetes-deploy: applies Deployment + Service, waits for rollout

8. finally block: reports pipeline status regardless of success/failure
```

## 8. Common operations

### View all pipeline runs

```bash
tkn pipelinerun list
```

### View logs of a specific run

```bash
tkn pipelinerun logs <run-name> -f
```

### View logs of a specific task in a run

```bash
tkn pipelinerun logs <run-name> -f --task=build-app
```

### Cancel a running pipeline

```bash
tkn pipelinerun cancel <run-name>
```

### Delete old pipeline runs

```bash
tkn pipelinerun delete --keep 5
```

### Describe a task (see params, steps, workspaces)

```bash
tkn task describe nextjs-install-build
```

### Re-run a failed pipeline (not applicable with triggers)

With triggers, just push again. The webhook will create a new PipelineRun.

### Check EventListener logs

```bash
kubectl logs -l eventlistener=github-push-listener -f
```

## 9. Debugging common issues

### Pipeline not triggering on push

1. Check webhook delivery in GitHub (Settings -> Webhooks -> Recent Deliveries).
2. Check EventListener logs for errors:
   ```bash
   kubectl logs -l eventlistener=github-push-listener
   ```
3. Verify the webhook secret matches between GitHub and the k8s secret.
4. Verify the CEL filter matches your branch (default: `refs/heads/main`).

### Task fails with permission denied

1. Check the service account has proper RBAC:
   ```bash
   kubectl get rolebinding tekton-triggers-binding -o yaml
   kubectl get clusterrolebinding tekton-pipeline-deploy-binding -o yaml
   ```

### Image push fails

1. Verify Docker credentials secret exists and is correct:
   ```bash
   kubectl get secret docker-registry-credentials
   ```
2. Verify the service account can access the secret.

### Build fails with out of memory

1. Increase workspace storage in `trigger-template.yaml` (the `volumeClaimTemplate` section).
2. For node builds, set `NODE_OPTIONS=--max-old-space-size=4096` in the build task.

### Cannot access Tekton Dashboard

1. Verify the dashboard pods are running:
   ```bash
   kubectl get pods -n tekton-pipelines -l app=tekton-dashboard
   ```
2. Re-run port-forward:
   ```bash
   kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097
   ```

## 10. File reference for this project

```
tekton/
├── tasks/
│   ├── git-clone.yaml              # Clones Git repository
│   ├── nextjs-install-build.yaml   # npm install + lint + build
│   ├── build-push-image.yaml       # Kaniko image build + push
│   └── kubernetes-deploy.yaml      # kubectl deploy + service
├── pipelines/
│   └── nextjs-build-deploy.yaml    # Chains all tasks + finally block
└── triggers/
    ├── trigger-binding.yaml        # Extracts fields from GitHub webhook
    ├── trigger-template.yaml       # Creates PipelineRun from extracted data
    ├── event-listener.yaml         # Receives webhooks, validates, filters
    └── rbac.yaml                   # Service accounts and permissions
setup-kind.sh                       # Bootstraps a local Kind cluster + registry
```

The application source code and `Dockerfile` live in the separate `autoelite` repo. The pipeline clones that repo at runtime.

## 11. Tekton vs GitHub Actions (quick comparison)

| Concept | Tekton | GitHub Actions |
|---|---|---|
| Where it runs | Your Kubernetes cluster | GitHub-hosted or self-hosted runners |
| Pipeline definition | Kubernetes YAML (CRDs) | YAML in `.github/workflows/` |
| A single job | Task | Job |
| A step in a job | Step (container) | Step (shell command or action) |
| Full pipeline | Pipeline | Workflow |
| Running a pipeline | PipelineRun | Workflow run |
| Shared storage | Workspaces (PVCs) | Artifacts or cache actions |
| Event triggers | EventListener + TriggerBinding + TriggerTemplate | `on: push`, `on: pull_request` |
| Secret management | Kubernetes Secrets | GitHub Secrets |
| Reusable components | Tekton Hub tasks | GitHub Marketplace actions |
| UI | Tekton Dashboard | GitHub Actions tab |

This comparison table is useful when you test Rosetta's migration workflow to convert these Tekton pipelines to GitHub Actions.
