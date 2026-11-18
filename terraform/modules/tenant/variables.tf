variable "name" {
  description = "Service name; namespace becomes <name>-<environment>"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,29}$", var.name))
    error_message = "name must be 3-30 chars: lowercase letters, digits, dashes; start with a letter."
  }
}

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "owner" {
  description = "Owning team (Backstage Group name). Granted the 'edit' role in the namespace."
  type        = string
}

variable "tier" {
  type    = string
  default = "small"
  validation {
    condition     = contains(["small", "medium", "large"], var.tier)
    error_message = "tier must be small, medium or large."
  }
}

variable "cost_center" {
  type    = string
  default = ""
}

variable "group_prefix" {
  description = "Prefix your OIDC provider adds to group names (e.g. 'oidc:'). Empty for plain names."
  type        = string
  default     = ""
}

variable "ingress_namespace" {
  type    = string
  default = "ingress-nginx"
}
