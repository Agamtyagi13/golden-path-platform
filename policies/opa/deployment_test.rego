package main

import rego.v1

good := {
	"kind": "Deployment",
	"metadata": {"name": "demo"},
	"spec": {"template": {
		"metadata": {"labels": {"owner": "team-a", "app.kubernetes.io/name": "demo"}},
		"spec": {
			"securityContext": {"runAsNonRoot": true},
			"containers": [{
				"name": "app",
				"image": "ghcr.io/acme/demo:1.2.3",
				"resources": {"requests": {"cpu": "50m"}, "limits": {"memory": "128Mi"}},
				"readinessProbe": {"httpGet": {"path": "/readyz", "port": 8080}},
				"livenessProbe": {"httpGet": {"path": "/healthz", "port": 8080}},
				"securityContext": {"allowPrivilegeEscalation": false},
			}],
		},
	}},
}

test_good_deployment_passes if {
	count(deny) == 0 with input as good
}

test_latest_tag_denied if {
	bad := json.patch(good, [{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "ghcr.io/acme/demo:latest"}])
	count(deny) > 0 with input as bad
}

test_untagged_image_denied if {
	bad := json.patch(good, [{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "ghcr.io/acme/demo"}])
	count(deny) > 0 with input as bad
}

test_registry_port_not_mistaken_for_tag if {
	bad := json.patch(good, [{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "localhost:5000/demo"}])
	count(deny) > 0 with input as bad
}

test_missing_owner_denied if {
	bad := json.patch(good, [{"op": "remove", "path": "/spec/template/metadata/labels/owner"}])
	count(deny) > 0 with input as bad
}

test_missing_limits_denied if {
	bad := json.patch(good, [{"op": "remove", "path": "/spec/template/spec/containers/0/resources/limits"}])
	count(deny) > 0 with input as bad
}

test_privileged_denied if {
	bad := json.patch(good, [{"op": "add", "path": "/spec/template/spec/containers/0/securityContext/privileged", "value": true}])
	count(deny) > 0 with input as bad
}

test_root_denied if {
	bad := json.patch(good, [{"op": "replace", "path": "/spec/template/spec/securityContext/runAsNonRoot", "value": false}])
	count(deny) > 0 with input as bad
}

test_non_workload_ignored if {
	count(deny) == 0 with input as {"kind": "Service", "metadata": {"name": "x"}}
}

test_unapproved_registry_denied if {
	bad := json.patch(good, [{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "docker.io/library/nginx:1.27"}])
	count(deny) > 0 with input as bad
}
