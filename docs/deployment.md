# Deployment guide

Two parts: the **platform** (cluster + guardrails) and the **portal** (Backstage). Do the platform first.

## A. Local (laptop or one EC2 instance) - no cloud bill beyond one VM

Prereqs: Docker, kind, kubectl, helm, Terraform >= 1.6 (or OpenTofu: `TF=tofu`), Python 3.12, conftest, kyverno CLI.

```bash
git clone https://github.com/YOUR_GITHUB_ORG/golden-path-platform && cd golden-path-platform
make test        # no cluster needed: OPA + Kyverno + pytest
make up          # kind + Kyverno + ingress-nginx + policies + tenant namespaces
make smoke       # scaffold, deploy, and prove violations are rejected -> docs/testing-evidence/smoke-test.log
```

## B. Backstage portal

```bash
./scripts/bootstrap-backstage.sh ../backstage-app     # needs Node 20/22 + yarn
export GITHUB_TOKEN=...            # fine-grained PAT (repo + workflow). Never commit it.
cd ../backstage-app && yarn dev
```

Before running, in `backstage/templates/golden-path-service/template.yaml` replace `YOUR_GITHUB_ORG` with your org, and
copy `backstage/app-config.golden-path.yaml` settings into `app-config.local.yaml`.
Open http://localhost:3000 -> **Create** -> *Golden Path - Python Microservice*.

For the **live deployment URL**: build the Backstage image (`yarn build:backend` + the Dockerfile Backstage generates),
push to GHCR, then `helm install backstage backstage/backstage -n backstage -f backstage/deploy/values.yaml`
on the kind/EKS cluster (create the `backstage-secrets` Secret first). Point `backstage.example.com` at the ingress
(or use `kubectl port-forward` + a tunnel such as Cloudflare Tunnel for a demo link).

## C. GitHub setup

1. Create repo `golden-path-platform`, push this folder.
2. Add secret `KUBECONFIG_B64` (`base64 -w0 ~/.kube/config`) if you want `environments-apply` to run against a reachable cluster.
3. Create GitHub Environment `platform-prod` with required reviewers.
4. Set repo permissions: Actions -> Read and write, allow PR creation.
