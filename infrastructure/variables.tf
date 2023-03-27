variable "github_pat" {}

variable "domain" {}

variable "container_registry" {}

variable "github_username" {}

variable "acme_email" {}

variable "kube_config_path" {
  default = "~/.kube/config"
}
