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
