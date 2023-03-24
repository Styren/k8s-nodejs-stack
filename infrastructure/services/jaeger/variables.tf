variable "namespace" {
  default = "default"
}

variable "helm_repository" {
  default = "https://jaegertracing.github.io/helm-charts"
}

variable "helm_chart" {
  default = "jaeger-operator"
}

variable "helm_version" {
  default = "2.24.0"
}

variable "domain" {}

variable "ingress_annotations" {}
