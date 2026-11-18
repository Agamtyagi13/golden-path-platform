# Conftest policies for rendered Kubernetes workloads.
# Same intent as policies/kyverno/*: fail in CI before the cluster ever sees it.
package main

import rego.v1

workloads := {"Deployment", "StatefulSet", "DaemonSet"}

is_workload if input.kind in workloads

pod_spec := input.spec.template.spec

containers contains c if {
	is_workload
	some c in pod_spec.containers
}

image_name(image) := last if {
	parts := split(image, "/")
	last := parts[count(parts) - 1]
}

untagged(image) if {
	not contains(image_name(image), ":")
	not contains(image, "@")
}

deny contains msg if {
	is_workload
	not input.spec.template.metadata.labels.owner
	msg := sprintf("%s/%s: pod template must have an 'owner' label", [input.kind, input.metadata.name])
}

deny contains msg if {
	is_workload
	not input.spec.template.metadata.labels["app.kubernetes.io/name"]
	msg := sprintf("%s/%s: pod template must have an 'app.kubernetes.io/name' label", [input.kind, input.metadata.name])
}

deny contains msg if {
	some c in containers
	endswith(c.image, ":latest")
	msg := sprintf("container '%s' must not use the ':latest' tag", [c.name])
}

deny contains msg if {
	some c in containers
	untagged(c.image)
	msg := sprintf("container '%s' image must be pinned to a tag or digest", [c.name])
}

deny contains msg if {
	some c in containers
	not c.resources.limits.memory
	msg := sprintf("container '%s' must set resources.limits.memory", [c.name])
}

deny contains msg if {
	some c in containers
	not c.resources.requests.cpu
	msg := sprintf("container '%s' must set resources.requests.cpu", [c.name])
}

deny contains msg if {
	some c in containers
	not c.readinessProbe
	msg := sprintf("container '%s' must define a readinessProbe", [c.name])
}

deny contains msg if {
	some c in containers
	not c.livenessProbe
	msg := sprintf("container '%s' must define a livenessProbe", [c.name])
}

deny contains msg if {
	some c in containers
	c.securityContext.privileged == true
	msg := sprintf("container '%s' must not be privileged", [c.name])
}

deny contains msg if {
	is_workload
	not pod_spec.securityContext.runAsNonRoot == true
	msg := sprintf("%s/%s: pod securityContext.runAsNonRoot must be true", [input.kind, input.metadata.name])
}

deny contains msg if {
	some c in containers
	not c.securityContext.allowPrivilegeEscalation == false
	msg := sprintf("container '%s' must set allowPrivilegeEscalation: false", [c.name])
}

approved_registries := ["ghcr.io/"]

deny contains msg if {
	some c in containers
	not any_approved(c.image)
	msg := sprintf("container '%s' image must come from an approved registry (%v)", [c.name, approved_registries])
}

any_approved(image) if {
	some prefix in approved_registries
	startswith(image, prefix)
}
