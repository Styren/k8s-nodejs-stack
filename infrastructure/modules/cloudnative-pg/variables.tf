variable "namespace" {
  default = "default"
}

variable "helm_repository" {
  default = "https://cloudnative-pg.github.io/charts"
}

variable "helm_chart" {
  default = "cloudnative-pg"
}

variable "domain" {}
