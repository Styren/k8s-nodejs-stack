resource "helm_release" "cert_manager" {
  name             = var.name
  version          = var.helm_version
  repository       = var.helm_repository
  chart            = var.helm_chart

  namespace        = "cert-manager"
  create_namespace = true

  wait = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

