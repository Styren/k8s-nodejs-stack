locals {
  grafana_host      = "grafana.${var.domain}"
  alertmanager_host = "alertmanager.${var.domain}"
  prometheus_host   = "prometheus.${var.domain}"
  thanos_host       = "thanos.${var.domain}"

  ingress_annotations = {
    "acme.cert-manager.io/http01-edit-in-place" : "true"
    "kubernetes.io/ingress.class" : "nginx"
    "kubernetes.io/tls-acme" : "true"
    "cert-manager.io/cluster-issuer" : "letsencrypt"
  }
  oauth_protected_ingress_annotations = merge(local.ingress_annotations, {
    "nginx.ingress.kubernetes.io/auth-url" : "https://oauth2.${var.domain}/oauth2/auth"
    "nginx.ingress.kubernetes.io/auth-signin" : "https://oauth2.${var.domain}/oauth2/start?rd=https://$host$uri"
  })
}

resource "helm_release" "prometheus_stack" {
  name       = var.prometheus_stack_name
  repository = var.helm_repository
  chart      = var.prometheus_stack_helm_chart
  version    = var.prometheus_stack_helm_version

  values = [
    templatefile("${path.module}/values.yaml", {
      namespace                     = var.namespace,
      grafana_host                  = local.grafana_host,
      alertmanager_host             = local.alertmanager_host,
      prometheus_host               = local.prometheus_host,
      thanos_host                   = local.thanos_host,
      ingress_annotations           = jsonencode(local.ingress_annotations),
    })
  ]
}
