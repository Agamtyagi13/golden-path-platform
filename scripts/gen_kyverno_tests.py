#!/usr/bin/env python3
"""Generate policies/tests/{resources,kyverno-test}.yaml (one good + one bad workload per rule)."""
import copy, pathlib, yaml

GOOD = {
    "apiVersion": "apps/v1", "kind": "Deployment",
    "metadata": {"name": "good", "namespace": "payments-dev"},
    "spec": {"replicas": 1, "selector": {"matchLabels": {"app": "x"}}, "template": {
        "metadata": {"labels": {"app": "x", "owner": "payments-team", "app.kubernetes.io/name": "x"}},
        "spec": {
            "securityContext": {"runAsNonRoot": True},
            "containers": [{
                "name": "app", "image": "ghcr.io/acme/x:1.0.0",
                "resources": {"requests": {"cpu": "50m", "memory": "64Mi"}, "limits": {"memory": "128Mi"}},
                "readinessProbe": {"httpGet": {"path": "/readyz", "port": 8080}},
                "livenessProbe": {"httpGet": {"path": "/healthz", "port": 8080}},
                "securityContext": {"allowPrivilegeEscalation": False, "privileged": False},
            }]}}},
}

def variant(name, mutate):
    d = copy.deepcopy(GOOD); d["metadata"]["name"] = name; mutate(d); return d
def tpl(d): return d["spec"]["template"]
def ctr(d): return tpl(d)["spec"]["containers"][0]

bad = {
    "bad-no-owner": lambda d: tpl(d)["metadata"]["labels"].pop("owner"),
    "bad-latest": lambda d: ctr(d).update(image="ghcr.io/acme/x:latest"),
    "bad-untagged": lambda d: ctr(d).update(image="ghcr.io/acme/x"),
    "bad-no-resources": lambda d: ctr(d).pop("resources"),
    "bad-no-probes": lambda d: (ctr(d).pop("readinessProbe"), ctr(d).pop("livenessProbe")),
    "bad-registry": lambda d: ctr(d).update(image="docker.io/evil/miner:1.0"),
    "bad-privileged": lambda d: ctr(d)["securityContext"].update(privileged=True),
    "bad-root": lambda d: tpl(d)["spec"]["securityContext"].update(runAsNonRoot=False),
    "bad-escalation": lambda d: ctr(d)["securityContext"].update(allowPrivilegeEscalation=True),
}
# (policy, rule, bad-resource(s) expected to fail)
matrix = [
    ("require-labels", "check-labels", ["bad-no-owner"]),
    ("disallow-latest-tag", "require-image-tag", ["bad-untagged"]),
    ("disallow-latest-tag", "validate-image-tag", ["bad-latest"]),
    ("require-resources", "check-resources", ["bad-no-resources"]),
    ("require-probes", "check-probes", ["bad-no-probes"]),
    ("restrict-image-registries", "approved-registries", ["bad-registry"]),
    ("pod-security", "deny-privileged", ["bad-privileged"]),
    ("pod-security", "run-as-non-root", ["bad-root"]),
    ("pod-security", "no-privilege-escalation", ["bad-escalation"]),
]
docs = [GOOD] + [variant(n, m) for n, m in bad.items()]
out = pathlib.Path(__file__).resolve().parent.parent / "policies" / "tests"
(out / "resources.yaml").write_text(yaml.safe_dump_all(docs, sort_keys=False))

results = []
for policy, rule, bads in matrix:
    for res, verdict in [("good", "pass")] + [(b, "fail") for b in bads]:
        results.append({"policy": policy, "rule": f"autogen-{rule}", "resources": [res],
                        "kind": "Deployment", "result": verdict})
test = {"apiVersion": "cli.kyverno.io/v1alpha1", "kind": "Test",
        "metadata": {"name": "golden-path-policies"},
        "policies": [f"../kyverno/{p}.yaml" for p in sorted({m[0] for m in matrix})],
        "resources": ["resources.yaml"], "results": results}
(out / "kyverno-test.yaml").write_text(yaml.safe_dump(test, sort_keys=False))
print("generated", len(docs), "resources,", len(results), "assertions")
