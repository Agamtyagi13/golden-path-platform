# Design choices

**Environment provisioning via pull request, not a direct API call.** Backstage never holds cloud/cluster
credentials. It opens a PR adding `tenants/<svc>-<env>.yaml`; CI plans it; a human-gated merge applies it.
This gives review, audit trail, rollback (`git revert`) and keeps the portal low-privilege.

**Two policy engines on purpose.** OPA/Conftest runs in CI for fast, cheap feedback (developer sees the failure on the PR).
Kyverno runs at admission as the non-bypassable backstop. They express the same rules; a test fails if the skeleton's
copy of the Rego drifts from `policies/opa/`, and `examples/violations/` must be rejected by both.

**Kyverno rules target `Pod`.** Kyverno auto-generates equivalent rules for Deployments/StatefulSets/DaemonSets/Jobs,
so bare Pods cannot slip through either.

**Skeleton files with their own `{{ }}` syntax are copied unrendered.** Backstage's Nunjucks uses `${{ }}`, the same as
GitHub Actions, and Helm uses `{{ }}`. The workflow and `chart/templates/*` are listed in `copyWithoutRender`
and derive names from the repo/chart instead of template values. `scripts/render_skeleton.py` reads the same list, so tests render exactly what Backstage would.

**Tiered quotas instead of free-form numbers.** Teams choose `small|medium|large`; the platform owns what those mean.
Changing a tier's numbers is one edit that PRs cleanly across all tenants.

**Pod Security Admission `restricted` on every tenant namespace** plus the chart already complies (non-root, seccomp, no
privilege escalation, dropped caps, read-only root FS), so the paved road is also the easiest road.

**Image tags are never `latest`.** CI deploys the commit SHA; chart default is a pinned version. Rollback = redeploy an earlier SHA.

**Plain HTTP health endpoints and a ClusterIP service**; ingress is opt-in (`ingress.enabled`).
