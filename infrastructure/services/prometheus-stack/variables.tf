variable "prometheus_stack_name" {
  default = "prometheus-stack"
}

variable "blackbox_exporter_name" {
  default = "blackbox-exporter"
}

variable "helm_repository" {
  default = "https://prometheus-community.github.io/helm-charts"
}

variable "prometheus_stack_helm_chart" {
  default = "kube-prometheus-stack"
}

variable "prometheus_stack_helm_version" {
  default = "45.6.0"
}

variable "blackbox_exporter_helm_chart" {
  default = "prometheus-blackbox-exporter"
}

variable "blackbox_exporter_helm_version" {
  default = "5.6.0"
}

variable "namespace" {
  default = "default"
}

variable "domain" {}

variable "ingress_annotations" {}
