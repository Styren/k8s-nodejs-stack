resource "helm_release" "cloudnative_pg" {
  name       = "cloudnative-pg"
  repository = var.helm_repository
  chart      = var.helm_chart
}
