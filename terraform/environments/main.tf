provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

locals {
  tenant_files = fileset("${path.module}/../../tenants", "*.yaml")
  tenants = {
    for f in local.tenant_files :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.module}/../../tenants/${f}"))
  }
}

module "tenant" {
  source   = "../modules/tenant"
  for_each = local.tenants

  name         = each.value.name
  environment  = each.value.environment
  owner        = each.value.owner
  tier         = try(each.value.tier, "small")
  cost_center  = try(each.value.cost_center, "")
  group_prefix = var.group_prefix
}

output "namespaces" {
  value = { for k, m in module.tenant : k => m.namespace }
}
