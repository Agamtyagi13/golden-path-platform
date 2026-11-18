locals {
  namespace = "${var.name}-${var.environment}"

  tiers = {
    small  = { cpu_requests = "1", cpu_limits = "2", memory_requests = "1Gi", memory_limits = "2Gi", pods = "10" }
    medium = { cpu_requests = "4", cpu_limits = "8", memory_requests = "4Gi", memory_limits = "8Gi", pods = "30" }
    large  = { cpu_requests = "16", cpu_limits = "32", memory_requests = "16Gi", memory_limits = "32Gi", pods = "100" }
  }
  quota = local.tiers[var.tier]

  labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "platform.example.com/tenant"  = var.name
    "owner"                        = var.owner
    "environment"                  = var.environment
    "cost-center"                  = var.cost_center
  }
}

# Cross-variable guardrails (variable validation cannot see other variables).
resource "terraform_data" "guardrails" {
  input = local.namespace

  lifecycle {
    precondition {
      condition     = !(var.environment == "dev" && var.tier == "large")
      error_message = "Guardrail: the 'large' tier is not allowed in dev. Use small or medium."
    }
    precondition {
      condition     = var.environment != "prod" || length(var.cost_center) > 0
      error_message = "Guardrail: prod environments require a cost_center."
    }
  }
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = local.namespace
    labels = merge(local.labels, {
      # Pod Security Admission: restricted is enforced by the cluster itself
      "pod-security.kubernetes.io/enforce" = "restricted"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    })
  }
  depends_on = [terraform_data.guardrails]
}

resource "kubernetes_resource_quota_v1" "this" {
  metadata {
    name      = "tier-${var.tier}"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"           = local.quota.cpu_requests
      "limits.cpu"             = local.quota.cpu_limits
      "requests.memory"        = local.quota.memory_requests
      "limits.memory"          = local.quota.memory_limits
      "pods"                   = local.quota.pods
      "services"               = "10"
      "persistentvolumeclaims" = "5"
    }
  }
}

resource "kubernetes_limit_range_v1" "defaults" {
  metadata {
    name      = "defaults"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "250m"
        memory = "256Mi"
      }
      default_request = {
        cpu    = "50m"
        memory = "64Mi"
      }
    }
  }
}

# --- Network isolation: deny everything, then open only what a normal service needs ---
resource "kubernetes_network_policy_v1" "default_deny" {
  metadata {
    name      = "default-deny-all"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy_v1" "allow_same_namespace" {
  metadata {
    name      = "allow-same-namespace"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
    ingress {
      from {
        pod_selector {}
      }
    }
    egress {
      to {
        pod_selector {}
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "allow_dns" {
  metadata {
    name      = "allow-dns-egress"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    pod_selector {}
    policy_types = ["Egress"]
    egress {
      to {
        namespace_selector {
          match_labels = { "kubernetes.io/metadata.name" = "kube-system" }
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "allow_ingress_controller" {
  metadata {
    name      = "allow-from-ingress-controller"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress"]
    ingress {
      from {
        namespace_selector {
          match_labels = { "kubernetes.io/metadata.name" = var.ingress_namespace }
        }
      }
    }
  }
}

# --- Access: owning team gets the built-in 'edit' role, scoped to this namespace only ---
resource "kubernetes_role_binding_v1" "owner_edit" {
  metadata {
    name      = "owner-edit"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }
  subject {
    kind      = "Group"
    name      = "${var.group_prefix}${var.owner}"
    api_group = "rbac.authorization.k8s.io"
  }
}
