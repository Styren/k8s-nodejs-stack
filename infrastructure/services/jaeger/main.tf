resource "helm_release" "jaeger_operator" {
  name       = "jaeger-operator"
  repository = var.helm_repository
  chart      = var.helm_chart
  version    = var.helm_version
}
