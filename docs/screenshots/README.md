# Screenshots to capture for the submission

Take these after `make up`, `make smoke` and Backstage running, and save them in this folder with these names.
The main README references them.

| File | What to show |
|---|---|
| `01-backstage-create.png` | Backstage -> Create page with the Golden Path template card |
| `02-template-form.png` | The filled-in form (name, owner, tier, cost center) |
| `03-scaffolder-run.png` | Scaffolder run page with all steps green and the three output links |
| `04-new-repo.png` | Generated GitHub repo (chart/, policy/, .github/workflows) |
| `05-catalog-entity.png` | The new Component in the Backstage catalog with owner + system |
| `06-env-pr.png` | The auto-opened PR adding `tenants/<svc>-<env>.yaml` with passing checks |
| `07-kubectl-guardrails.png` | `kubectl -n <ns> get resourcequota,limitrange,networkpolicy` |
| `08-kyverno-deny.png` | `kubectl apply -f examples/violations/latest-tag.yaml` being denied |
| `09-smoke-test.png` | End of `make smoke` showing `RESULT: N passed, 0 failed` |
| `10-actions-green.png` | Service repo Actions run (test, chart-policy, build-scan-push, deploy) |
