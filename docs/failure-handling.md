# Failures handled

| Failure | How it is handled |
|---|---|
| Invalid service name / cost center / env | Rejected in the Backstage form (regex + enum) before anything is created |
| Duplicate requests for the same tenant | Branch and file names are deterministic (`onboard-<svc>-<env>`, `tenants/<svc>-<env>.yaml`), so duplicates collide visibly in Git instead of creating two namespaces; the Terraform `for_each` key is the file name |
| Repo created but PR step fails | No cluster change happens without a merged PR, so a partial run is safe. Recovery is manual: open the PR by hand with the same `tenants/*.yaml` (a known limitation - see README) |
| `large` tier in dev / prod without cost center | Terraform `precondition` fails the plan with a clear message; PR check turns red |
| Terraform apply races between merges | The apply job is gated by a GitHub Environment; for teams, enable the remote locked backend in `backend.tf.example` (demo uses local state) |
| Non-compliant manifest | Conftest fails the service PR; if it bypasses CI, Kyverno denies at admission with the policy message |
| Bad rollout | `helm upgrade --atomic --timeout 3m` rolls back automatically if pods never become ready |
| Vulnerable image | Trivy exits non-zero on HIGH/CRITICAL (unfixed ignored), blocking the push |
| Secrets | Nothing sensitive is committed: tokens come from env/Secrets (`GITHUB_TOKEN`, `KUBECONFIG_B64`); `.gitignore` excludes tfstate, tfvars, kubeconfig |
| Noisy neighbour / runaway pod | ResourceQuota + LimitRange defaults; Kyverno requires requests/limits |
| Lateral movement | Default-deny NetworkPolicy; only same-namespace, DNS and ingress-controller traffic allowed |
| Node loses a replica during maintenance | PodDisruptionBudget in the chart, `replicas >= 2` by default |
