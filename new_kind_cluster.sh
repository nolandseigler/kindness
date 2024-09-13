#!/usr/bin/env bash

# https://kind.sigs.k8s.io/docs/user/ingress/#create-cluster

command -v kind >/dev/null 2>&1 || { echo >&2 "'kind' required but it's not installed.  Aborting."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo >&2 "'kubectl' required but it's not installed.  Aborting."; exit 1; }

root_dir=$(git rev-parse --show-toplevel)

echo "preconditions met, deleting default kind cluster and creating new kind cluster using ${root_dir}/kind-config.yaml"

kind delete cluster --name kindness
kind create cluster --config "${root_dir}/kind-config.yaml" -v 99 --wait 600s --name kindness

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

kubectl apply -f hello-world.yaml

kubectl wait --for=condition=ready pod -l 'app in (foo, bar)'

# it says ready bit its still not ready for curl to hit it.
sleep 30

# should output "foo-app"
curl localhost:80/foo/hostname
# should output "bar-app"
curl localhost:80/bar/hostname
