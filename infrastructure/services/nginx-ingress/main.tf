resource "helm_release" "nginx_ingress" {
  name       = var.name
  version    = var.helm_version
  repository = var.helm_repository
  chart      = var.helm_chart
}
