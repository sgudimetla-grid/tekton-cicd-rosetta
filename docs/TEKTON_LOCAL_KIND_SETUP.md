# Tekton on Local Kind Cluster — Complete Guide

Everything you need to set up a Kind cluster, install Tekton, run the pipeline, deploy the app, and access it from your browser. Copy-paste friendly.

## Repos involved

Two repos work together. You're reading the docs of the first one.

| Repo | What it contains | Role in this guide |
|---|---|---|
| `tekton-cicd` (this repo) | Tekton tasks, pipeline, triggers, RBAC, `setup-kind.sh` | You apply these to the cluster |
| `autoelite` | Next.js car-marketplace app + `Dockerfile` | The pipeline clones this repo, builds an image, and deploys it |

Before you start, clone the AutoElite app repo somewhere — the pipeline won't have anything to build without it:

```bash
git clone https://github.com/sgudimetla-grid/autoelite.git ~/autoelite
```

If you've forked it under a different account, substitute that URL in every place this guide says `sgudimetla-grid/autoelite.git` (Part 6 PipelineRun examples, the curl payload, the GitHub webhook URL).

---

## Part 1: Install Tools

### macOS

```bash
# Docker Desktop (required — Kind runs containers inside Docker)
# Download from https://www.docker.com/products/docker-desktop/

# kubectl — Kubernetes CLI
brew install kubectl

# kind — Kubernetes in Docker
brew install kind

# tkn — Tekton CLI (view runs, logs, trigger pipelines)
brew install tektoncd-cli

# ngrok — tunnel for GitHub webhooks (optional, only for Option C)
brew install ngrok
```

### Linux

```bash
# Docker Engine
# Follow https://docs.docker.com/engine/install/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# tkn
curl -LO https://github.com/tektoncd/cli/releases/latest/download/tkn_Linux_x86_64.tar.gz
tar xvzf tkn_Linux_x86_64.tar.gz -C /usr/local/bin tkn
```

### Verify all tools

```bash
docker --version          # Docker version 27.x+
kubectl version --client  # Client Version: v1.29+
kind --version            # kind v0.24+
tkn version               # Client version: 0.38+
```

---

## Part 2: Create Kind Cluster with Local Registry

A local Docker registry lets the pipeline push images that Kind can pull. This makes the full flow work end-to-end.

The registry is reachable two ways:

| Address | Who uses it | When |
|---|---|---|
| `localhost:5001` | You, from your Mac/Linux host | Browsing the registry, e.g. `curl http://localhost:5001/v2/_catalog` |
| `kind-registry:5000` | Pods inside the Kind cluster | Pipeline pushes here, Kubernetes pulls from here |

Pods cannot resolve `localhost:5001` — `localhost` inside a pod is the pod itself, not your host. So **inside the cluster everything uses `kind-registry:5000`**.

Save this as `setup-kind.sh` in the project root:

```bash
#!/bin/bash
set -eu

REG_NAME='kind-registry'
REG_PORT='5001'

echo "=== Starting local Docker registry ==="
if [ "$(docker inspect -f '{{.State.Running}}' "${REG_NAME}" 2>/dev/null || true)" != 'true' ]; then
  docker run -d --restart=always \
    -p "127.0.0.1:${REG_PORT}:5000" \
    --network bridge \
    --name "${REG_NAME}" \
    registry:2
  echo "Registry started on localhost:${REG_PORT}"
else
  echo "Registry already running"
fi

echo "=== Creating Kind cluster ==="
cat <<YAML | kind create cluster --name tekton-test --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REG_PORT}"]
      endpoint = ["http://${REG_NAME}:5000"]
YAML

echo "=== Connecting registry to Kind network ==="
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REG_NAME}")" = 'null' ]; then
  docker network connect "kind" "${REG_NAME}"
fi

echo "=== Registering local registry with cluster ==="
cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REG_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
YAML

echo ""
echo "=== Done ==="
echo "Cluster: kind-tekton-test"
echo "Registry: localhost:${REG_PORT}"
echo "Use 'localhost:${REG_PORT}/nextjs-app' as the image name in pipelines"
```

Run it:

```bash
chmod +x setup-kind.sh
bash setup-kind.sh
```

Verify:

```bash
kubectl get nodes
# NAME                        STATUS   ROLES           AGE
# tekton-test-control-plane   Ready    control-plane   30s

docker ps --filter name=kind-registry --format "{{.Names}}: {{.Status}}"
# kind-registry: Up 30 seconds
```

### 2.1 Teach the cluster that `kind-registry:5000` is HTTP (one-time per cluster)

`setup-kind.sh` configures containerd to recognize `localhost:5001` as an insecure (HTTP) registry — but pods cannot reach `localhost:5001` (their `localhost` is the pod itself). Pods and Kubernetes pull from `kind-registry:5000` instead, and containerd needs to know **that** name is also HTTP. Without this step you will get:

```
ImagePullBackOff
http: server gave HTTP response to HTTPS client
```

Run this patch every time you create a fresh Kind cluster:

```bash
docker exec tekton-test-control-plane sh -c 'awk "
/\[plugins\.\"io\.containerd\.grpc\.v1\.cri\"\.registry\.mirrors\]/ {
  print
  print \"        [plugins.\\\"io.containerd.grpc.v1.cri\\\".registry.mirrors.\\\"kind-registry:5000\\\"]\"
  print \"          endpoint = [\\\"http://kind-registry:5000\\\"]\"
  next
}
{ print }
" /etc/containerd/config.toml > /tmp/config.toml && mv /tmp/config.toml /etc/containerd/config.toml'

docker exec tekton-test-control-plane systemctl restart containerd
sleep 5
kubectl get nodes
```

Verify the mirror is now registered:

```bash
docker exec tekton-test-control-plane grep -A6 "registry.mirrors" /etc/containerd/config.toml
```

You should see entries for **both** `localhost:5001` and `kind-registry:5000`, each pointing to `http://kind-registry:5000`.

> If you'd rather not run this patch manually each time, add the same mirror block to `setup-kind.sh` inside the `containerdConfigPatches` section so it's baked into every new cluster.

---

## Part 3: Install Tekton in the Cluster

### Install Tekton Pipelines

```bash
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

### Install Tekton Triggers

```bash
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
```

### Install Tekton Dashboard

```bash
kubectl apply -f https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
```

### Wait for Tekton to be ready

```bash
echo "Waiting for Tekton pods..."
kubectl wait --for=condition=Ready pods --all -n tekton-pipelines --timeout=120s
echo "All Tekton pods are running"
```

Verify:

```bash
kubectl get pods -n tekton-pipelines
```

You should see 5-6 pods all in `Running` state:

```
NAME                                                 READY   STATUS
tekton-pipelines-controller-xxxxx                    1/1     Running
tekton-pipelines-webhook-xxxxx                       1/1     Running
tekton-triggers-controller-xxxxx                     1/1     Running
tekton-triggers-webhook-xxxxx                        1/1     Running
tekton-triggers-core-interceptors-xxxxx              1/1     Running
tekton-dashboard-xxxxx                               1/1     Running
```

---

## Part 4: Create Prerequisites

Run these from the project root (`tekton-cicd/`):

```bash
# 1. Create the namespace where the app will be deployed
kubectl create namespace dev

# 2. Create Docker credentials for local registry (no auth needed)
kubectl create secret generic docker-registry-credentials \
  --from-literal=config.json='{}'

# 3. Create GitHub webhook secret (used by EventListener)
kubectl create secret generic github-webhook-secret \
  --from-literal=webhook-secret=my-test-secret
```

Verify:

```bash
kubectl get namespace dev
kubectl get secret docker-registry-credentials
kubectl get secret github-webhook-secret
```

---

## Part 5: Apply Pipeline Resources

```bash
# Service accounts and RBAC permissions
kubectl apply -f tekton/triggers/rbac.yaml

# All Tasks (git-clone, nextjs-install-build, build-push-image, kubernetes-deploy)
kubectl apply -f tekton/tasks/

# Pipeline (chains all tasks together)
kubectl apply -f tekton/pipelines/

# Trigger resources (binding, template, event listener)
kubectl apply -f tekton/triggers/
```

Verify everything:

```bash
echo "=== Tasks ==="
tkn task list

echo ""
echo "=== Pipeline ==="
tkn pipeline list

echo ""
echo "=== EventListener ==="
kubectl get eventlistener

echo ""
echo "=== EventListener Service ==="
kubectl get svc -l eventlistener=github-push-listener
```

---

## Part 6: Trigger the Pipeline

> **Before triggering:** the pipeline clones from your GitHub remote, so make sure your changes are committed and pushed. Run `git push origin main` if anything is uncommitted — otherwise the build will fail on a missing `package.json`.

You have three options. All three run the same pipeline — they differ only in how the PipelineRun is created.

### Option A: Direct PipelineRun (simplest — no triggers involved)

Creates a PipelineRun directly with `kubectl`. Skips the trigger chain entirely.
Best for: first-time testing, verifying tasks work.

```bash
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: nextjs-direct-
spec:
  pipelineRef:
    name: nextjs-build-deploy
  params:
    - name: repo-url
      value: "https://github.com/sgudimetla-grid/autoelite.git"
    - name: revision
      value: main
    - name: image-name
      value: "kind-registry:5000/nextjs-app"
    - name: image-tag
      value: direct-test
    - name: app-name
      value: nextjs-app
    - name: deploy-namespace
      value: dev
    - name: node-version
      value: "20"
    - name: replicas
      value: "1"
  workspaces:
    - name: shared-workspace
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
    - name: docker-credentials
      secret:
        secretName: docker-registry-credentials
  taskRunTemplate:
    serviceAccountName: tekton-pipeline-sa
EOF
```

Watch logs:

```bash
tkn pipelinerun logs -f --last
```

### Option B: Simulate GitHub webhook with curl (tests full trigger chain)

Sends a fake GitHub push event to the EventListener. Tests: EventListener -> GitHub interceptor -> CEL filter -> TriggerBinding -> TriggerTemplate -> PipelineRun.
Best for: validating the entire trigger setup without needing GitHub.

Terminal 1 — port-forward the EventListener:

```bash
kubectl port-forward svc/el-github-push-listener 8080:8080
```

Terminal 2 — send the fake webhook:

```bash
PAYLOAD='{"ref":"refs/heads/main","after":"a1b2c3d4e5f6","head_commit":{"id":"a1b2c3d4e5f6","message":"test local trigger"},"repository":{"clone_url":"https://github.com/sgudimetla-grid/autoelite.git"},"pusher":{"name":"sgudimetla-grid"}}'

SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac 'my-test-secret' | awk '{print $2}')

curl -v -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -d "$PAYLOAD"
```

If successful, you'll see a response with the created PipelineRun name.

Watch it:

```bash
tkn pipelinerun logs -f --last
```

#### If webhook validation fails

Check EventListener logs:

```bash
kubectl logs -l eventlistener=github-push-listener --tail=20
```

Common issues:
- Secret mismatch: ensure `my-test-secret` matches both the curl HMAC and the k8s secret.
- Missing headers: `X-GitHub-Event` and `X-Hub-Signature-256` are both required.

### Option C: Real GitHub webhook via ngrok (tests real end-to-end)

Makes GitHub actually send webhooks to your local cluster. Tests the real push-to-deploy flow.
Best for: final validation before production.

Terminal 1 — port-forward:

```bash
kubectl port-forward svc/el-github-push-listener 8080:8080
```

Terminal 2 — start ngrok:

```bash
ngrok http 8080
```

ngrok shows a public URL like:

```
Forwarding  https://a1b2c3d4.ngrok-free.app -> http://localhost:8080
```

Set up the webhook in GitHub:

1. Go to https://github.com/sgudimetla-grid/tekton-cicd/settings/hooks
2. Click "Add webhook"
3. **Payload URL**: paste the ngrok HTTPS URL (e.g., `https://a1b2c3d4.ngrok-free.app`)
4. **Content type**: `application/json`
5. **Secret**: `my-test-secret`
6. **Which events**: "Just the push event"
7. Click "Add webhook"

Now push any change to `main`:

```bash
git add . && git commit -m "trigger pipeline" && git push origin main
```

Watch the pipeline run:

```bash
tkn pipelinerun logs -f --last
```

Check webhook delivery status in GitHub: Settings -> Webhooks -> Recent Deliveries. Green checkmark means GitHub successfully sent the event.

### Option comparison

| | Option A: Direct | Option B: Curl | Option C: ngrok |
|---|---|---|---|
| **What it tests** | Pipeline only | Triggers + Pipeline | Real webhook + Triggers + Pipeline |
| **Needs port-forward** | No | Yes | Yes |
| **Needs ngrok** | No | No | Yes |
| **Needs GitHub webhook** | No | No | Yes |
| **Complexity** | Low | Medium | Higher |
| **Recommended for** | First test | Trigger validation | Final end-to-end |

---

## Part 7: Monitor Pipeline Execution

### Watch logs live

```bash
tkn pipelinerun logs -f --last
```

### List all runs

```bash
tkn pipelinerun list
```

Output:

```
NAME                    STARTED        DURATION   STATUS
nextjs-direct-abc123    2 minutes ago  3m45s      Succeeded
```

### View specific task logs

```bash
tkn pipelinerun logs <run-name> --task=clone
tkn pipelinerun logs <run-name> --task=build-app
tkn pipelinerun logs <run-name> --task=build-image
tkn pipelinerun logs <run-name> --task=deploy
```

### Use Tekton Dashboard (visual)

```bash
kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097
```

Open http://localhost:9097

You can see:
- all PipelineRuns with status
- task-by-task progress bars
- step-level logs
- timing for each step

### What each task does and how long it takes

| Task | What happens | Typical time |
|---|---|---|
| `clone` | Clones repo from GitHub | 5-15 seconds |
| `build-app` | npm install + lint + next build | 2-4 minutes |
| `build-image` | Kaniko builds Docker image + push to registry | 1-3 minutes |
| `deploy` | kubectl apply Deployment + Service, wait for rollout | 30-60 seconds |
| `report-status` | Prints final status (finally block) | 2-3 seconds |

Total run: ~5-8 minutes.

---

## Part 8: Access the Deployed Application

After the pipeline succeeds, your app is running in the `dev` namespace.

### Verify the deployment

```bash
echo "=== Deployment ==="
kubectl get deployment -n dev

echo ""
echo "=== Pods ==="
kubectl get pods -n dev

echo ""
echo "=== Service ==="
kubectl get svc -n dev
```

Expected:

```
=== Deployment ===
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
nextjs-app   1/1     1            1           30s

=== Pods ===
NAME                          READY   STATUS    AGE
nextjs-app-6f8b9d4c5-x7k2m   1/1     Running   30s

=== Service ===
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)
nextjs-app   ClusterIP   10.96.45.12   <none>        80/TCP
```

### Access from your browser

```bash
kubectl port-forward -n dev svc/nextjs-app 3000:80
```

Open http://localhost:3000

You should see the **AutoElite** car e-commerce app with:
- Hero section and featured cars on the home page
- "Cars" link to browse all 9 vehicles
- Category filters (Electric, Sports, SUV)
- Car detail pages with specs
- Working cart and checkout flow

### Validate the app is working

Run through this checklist:

```
[ ] Home page loads at http://localhost:3000
[ ] Click "Browse All Cars" — catalog page loads with 9 cars
[ ] Click "Electric" filter — shows only electric cars
[ ] Click "Details" on any car — detail page with specs loads
[ ] Click "Add to Cart" — cart badge in header updates
[ ] Click "Cart" — cart page shows added items
[ ] Adjust quantity with +/- buttons
[ ] Click "Proceed to Checkout" — checkout form loads
[ ] Fill form and click "Place Order" — success page appears
```

### Check pod logs

```bash
kubectl logs -n dev -l app=nextjs-app -f
```

### Quick health check

```bash
kubectl exec -n dev deployment/nextjs-app -- wget -qO- http://localhost:3000 | head -20
```

---

## Part 9: Run the Pipeline Again (re-deploy)

The application code lives in the separate **autoelite** repo. To re-deploy with a new image, push a change *there* and trigger a new pipeline run *here*:

```bash
# In your autoelite checkout — make any change and push it
cd /path/to/autoelite
echo "<!-- updated -->" >> app/page.js
git add . && git commit -m "update app"
git push origin main

# Back in tekton-cicd — trigger pipeline (Option A — direct)
cd /path/to/tekton-cicd
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: nextjs-redeploy-
spec:
  pipelineRef:
    name: nextjs-build-deploy
  params:
    - name: repo-url
      value: "https://github.com/sgudimetla-grid/autoelite.git"
    - name: revision
      value: main
    - name: image-name
      value: "kind-registry:5000/nextjs-app"
    - name: image-tag
      value: v2
    - name: app-name
      value: nextjs-app
    - name: deploy-namespace
      value: dev
  workspaces:
    - name: shared-workspace
      volumeClaimTemplate:
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 1Gi
    - name: docker-credentials
      secret:
        secretName: docker-registry-credentials
  taskRunTemplate:
    serviceAccountName: tekton-pipeline-sa
EOF

# Watch
tkn pipelinerun logs -f --last
```

The deploy task does a rolling update — the old pod is replaced by the new one with zero downtime.

---

## Part 10: Where Everything Lives in the Cluster

```
Kind Cluster (tekton-test)
│
├── tekton-pipelines namespace
│   ├── tekton-pipelines-controller      (runs your pipelines)
│   ├── tekton-pipelines-webhook         (validates pipeline YAML)
│   ├── tekton-triggers-controller       (manages triggers)
│   ├── tekton-triggers-webhook          (validates trigger YAML)
│   ├── tekton-triggers-core-interceptors (GitHub/CEL interceptors)
│   └── tekton-dashboard                 (web UI on port 9097)
│
├── default namespace
│   ├── Tasks (git-clone, nextjs-install-build, build-push-image, kubernetes-deploy)
│   ├── Pipeline (nextjs-build-deploy)
│   ├── EventListener (github-push-listener → creates svc/el-github-push-listener:8080)
│   ├── TriggerBinding (github-push-binding)
│   ├── TriggerTemplate (nextjs-build-deploy-template)
│   ├── ServiceAccount (tekton-triggers-sa, tekton-pipeline-sa)
│   ├── PipelineRuns (created per trigger/manual run)
│   └── TaskRuns (created by PipelineRuns, one per task)
│
├── dev namespace (your deployed application)
│   ├── Deployment: nextjs-app (runs your container)
│   ├── Pods: nextjs-app-xxxxx (actual running containers)
│   └── Service: nextjs-app (port 80 → pod port 3000)
│
└── External: kind-registry container
    ├── localhost:5001  (host-side access for you)
    └── kind-registry:5000  (cluster-side access for pipeline + kubelet)
        Stores built Docker images (kind-registry:5000/nextjs-app:tag)

Your browser
  └── kubectl port-forward -n dev svc/nextjs-app 3000:80
      └── http://localhost:3000 → Service → Pod → Next.js app
```

---

## Part 11: Useful Commands Reference

```bash
# === Pipeline operations ===
tkn pipelinerun list                          # list all runs
tkn pipelinerun logs -f --last                # stream logs of latest run
tkn pipelinerun logs <name> --task=build-app  # logs for specific task
tkn pipelinerun cancel <name>                 # cancel running pipeline
tkn pipelinerun delete --all                  # cleanup old runs

# === Inspect resources ===
tkn task list                                 # list all tasks
tkn pipeline describe nextjs-build-deploy     # pipeline details
tkn taskrun list                              # list task executions

# === Check deployed app ===
kubectl get all -n dev                        # everything in dev namespace
kubectl logs -n dev -l app=nextjs-app -f      # app logs
kubectl describe deployment -n dev nextjs-app # deployment details

# === Debug triggers ===
kubectl get eventlistener                     # trigger status
kubectl logs -l eventlistener=github-push-listener  # trigger logs

# === Debug pipeline ===
kubectl logs -n tekton-pipelines -l app=tekton-pipelines-controller --tail=50

# === Port-forwards ===
kubectl port-forward -n dev svc/nextjs-app 3000:80                        # app
kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097   # dashboard
kubectl port-forward svc/el-github-push-listener 8080:8080                # triggers

# === Check local registry ===
curl -s http://localhost:5001/v2/_catalog      # list images
curl -s http://localhost:5001/v2/nextjs-app/tags/list  # list tags
```

---

## Part 12: Troubleshooting

### Pipeline not starting

```bash
# Check if PipelineRun was created
tkn pipelinerun list

# If empty, check EventListener logs
kubectl logs -l eventlistener=github-push-listener --tail=30
```

### Task stuck in Pending

PVC might not be bound:

```bash
kubectl get pvc
kubectl get storageclass
```

Kind has `standard` StorageClass by default. If missing, recreate the cluster.

### Build fails with OOMKilled

Docker Desktop needs enough memory:
- Go to Docker Desktop -> Settings -> Resources
- Set Memory to 8GB or higher
- Restart Docker Desktop and recreate the cluster

### Image push fails

Check the local registry is running:

```bash
docker ps --filter name=kind-registry
curl http://localhost:5001/v2/
```

If not running:

```bash
docker start kind-registry
```

### Deploy fails with ImagePullBackOff

The image name in the pipeline must match what Kind can pull:

```bash
# Check what's in the registry
curl -s http://localhost:5001/v2/nextjs-app/tags/list

# Check the pod error
kubectl describe pod -n dev -l app=nextjs-app
```

### `build-app` fails with "package.json not found" / ENOENT

The pipeline clones the **remote** `main` branch of the **autoelite** repo — not your local working tree. If you have uncommitted/unpushed changes in your autoelite checkout, the clone won't include them.

```bash
cd /path/to/autoelite
git status                  # any "untracked files"? commit and push them
git log origin/main -1      # confirm the commit you expect is on the remote
git push origin main
```

Then re-trigger the pipeline from this repo.

### `build-image` fails with "connection refused" to `localhost:5001`

The pod is trying to reach `localhost:5001`, but inside a pod `localhost` is the pod itself. Use `kind-registry:5000` instead — that's the registry's hostname on the Kind Docker network.

Make sure your PipelineRun (or TriggerTemplate) sets:

```yaml
- name: image-name
  value: "kind-registry:5000/nextjs-app"
```

### Deployed pod stuck in `ImagePullBackOff` with "HTTP response to HTTPS client"

Containerd doesn't know `kind-registry:5000` is an HTTP registry, so it tries HTTPS and fails. Run the one-time containerd patch from **Part 2.1**, then delete the stuck pod so it retries:

```bash
kubectl delete pod -n dev -l app=nextjs-app
```

This happens after every `kind delete cluster` + recreate, unless you've added the mirror block directly into `setup-kind.sh`.

### `deploy` fails with `bitnami/kubectl` ImagePull error

Bitnami sunset their public images. The deploy task now uses `alpine/k8s:1.29.4`. If you see this error, re-apply the latest task:

```bash
kubectl apply -f tekton/tasks/kubernetes-deploy.yaml
```

### Webhook curl returns 403 or no response

```bash
# Verify the secret matches
kubectl get secret github-webhook-secret -o jsonpath='{.data.webhook-secret}' | base64 -d

# Check EventListener is healthy
kubectl get eventlistener github-push-listener -o jsonpath='{.status.conditions}'
```

### Port 8080 or 3000 already in use

```bash
lsof -i :8080
lsof -i :3000
kill <PID>
```

---

## Part 13: Cleanup

```bash
# Delete the Kind cluster (removes all k8s resources)
kind delete cluster --name tekton-test

# Remove the local registry container
docker rm -f kind-registry

# Remove the Kind network (optional)
docker network rm kind
```

To start fresh, run `setup-kind.sh` again and repeat from Part 3.
