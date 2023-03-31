variable "prometheus_stack_name" {
  default = "prometheus-stack"
}

variable "blackbox_exporter_name" {
  default = "blackbox-exporter"
}

variable "prometheus_helm_repository" {
  default = "https://prometheus-community.github.io/helm-charts"
}

variable "prometheus_stack_helm_chart" {
  default = "kube-prometheus-stack"
}

variable "prometheus_stack_helm_version" {
  default = "45.6.0"
}

variable "jaeger_helm_repository" {
  default = "https://jaegertracing.github.io/helm-charts"
}

variable "jaeger_helm_chart" {
  default = "jaeger-operator"
}

variable "jaeger_helm_version" {
  default = "2.41.0"
}

variable "domain" {}

variable "ingress_annotations" {}
