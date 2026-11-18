#!/usr/bin/env bash
# One command local platform: kind + Kyverno + ingress-nginx + guardrail policies + tenant namespaces.
# Requires: docker, kind, kubectl, terraform (or tofu), helm
set -euo pipefail
cd "$(dirname "$0")/.."
TF="${TF:-terraform}"

kind get clusters | grep -qx golden-path || kind create cluster --config scripts/kind-config.yaml
kubectl config use-context kind-golden-path

(cd terraform/platform && $TF init -input=false && $TF apply -auto-approve -var kube_context=kind-golden-path)

kubectl wait --for=condition=Available deployment --all -n kyverno --timeout=300s
kubectl apply -k policies/kyverno
kubectl get cpol

(cd terraform/environments && $TF init -input=false && $TF apply -auto-approve -var kube_context=kind-golden-path)
kubectl get ns -l app.kubernetes.io/managed-by=terraform
