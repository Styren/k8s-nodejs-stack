variable "name" {
  default = "cert-manager"
}

variable "helm_repository" {
  default = "https://charts.jetstack.io"
}

variable "helm_chart" {
  default = "cert-manager"
}

variable "helm_version" {
  default = "v1.7.2"
}
