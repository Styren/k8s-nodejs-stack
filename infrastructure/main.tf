locals {
  ingress_annotations = {
    "acme.cert-manager.io/http01-edit-in-place" : "true"
    "kubernetes.io/ingress.class" : "nginx"
    "kubernetes.io/tls-acme" : "true"
    "cert-manager.io/cluster-issuer" : "letsencrypt"
  }
}

module "cert_manager" {
  source = "./services/cert-manager"
}

resource "kubernetes_manifest" "jaeger" {
  manifest = {
    apiVersion = "jaegertracing.io/v1"
    kind       = "Jaeger"
    metadata = {
      name      = "jaeger"
      namespace  = "default"
    }
    spec = {
      ingress = {
        enabled = false
      }
    }
  }
}

resource "kubernetes_ingress_v1" "jaeger" {
  metadata {
    name        = "jaeger"
    namespace  = "default"
    annotations = local.ingress_annotations
  }
  spec {
    tls {
      hosts       = ["jaeger.${var.domain}"]
      secret_name = "jaeger-tls"
    }

    rule {
      host = "jaeger.${var.domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "jaeger-query"
              port {
                number = 16686
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "postgres" {
  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      namespace  = "default"
      name      = "main-database"
    }
    spec = {
      instances = 3
      storage = {
        size = "10Gi"
      }
    }
  }
}
