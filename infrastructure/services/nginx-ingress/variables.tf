variable "name" {
  default = "nginx-ingress"
}

variable "helm_repository" {
  default = "https://kubernetes.github.io/ingress-nginx"
}

variable "helm_chart" {
  default = "ingress-nginx"
}

variable "helm_version" {
  default = "4.0.18"
}

variable "kube_config_path" {
  default = "~/.kube/config"
}
