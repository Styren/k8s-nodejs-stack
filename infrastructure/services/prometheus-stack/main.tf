locals {
  namespace  = "prometheus-stack"
  grafana_host      = "dashboard.${var.domain}"

  ingress_annotations = {
    "acme.cert-manager.io/http01-edit-in-place" : "true"
    "kubernetes.io/ingress.class" : "nginx"
    "kubernetes.io/tls-acme" : "true"
    "cert-manager.io/cluster-issuer" : "letsencrypt"
  }
}

resource "random_password" "grafana" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "grafana_admin_password" {
  metadata {
    name      = "grafana-password"
    namespace = local.namespace
  }

  data = {
    "password" : random_password.grafana.result
  }

  depends_on = [helm_release.prometheus_stack]
}

resource "helm_release" "prometheus_stack" {
  name       = var.prometheus_stack_name
  repository = var.helm_repository
  chart      = var.prometheus_stack_helm_chart
  version    = var.prometheus_stack_helm_version

  namespace  = local.namespace
  create_namespace  = true

  values = [
    templatefile("${path.module}/values.yaml", {
      namespace                     = var.namespace,
      grafana_host                  = local.grafana_host,
      ingress_annotations           = jsonencode(local.ingress_annotations),
    })
  ]

  set_sensitive {
    name  = "grafana.adminPassword"
    value = random_password.grafana.result
  }
}
