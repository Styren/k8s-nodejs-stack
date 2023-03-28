locals {
  ingress_annotations = {
    "acme.cert-manager.io/http01-edit-in-place" : "true"
    "kubernetes.io/ingress.class" : "nginx"
    "kubernetes.io/tls-acme" : "true"
    "cert-manager.io/cluster-issuer" : "letsencrypt"
  }
}

resource "kubernetes_config_map" "domain" {
  metadata {
    name      = "domain"
  }

  data = {
    domain = var.domain
  }
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

resource "kubernetes_default_service_account" "default" {
  metadata {
    namespace = "default"
  }
  image_pull_secret {
    name = kubernetes_secret.github_pat.metadata.0.name
  }
}

resource "kubernetes_secret" "github_pat" {
  metadata {
    name = "github-pat"
  }
  data = {
    ".dockerconfigjson" = <<EOF
    {
      "auths": {
        "${var.container_registry}": {
          "username": "${var.github_username}",
          "password": "${var.github_pat}",
          "auth": "${base64encode("${var.github_username}:${var.github_pat}")}"
        }
      }
    }
    EOF
  }
  type = "kubernetes.io/dockerconfigjson"
}

resource "helm_release" "nats" {
  name       = "nats"
  repository = "https://nats-io.github.io/k8s/helm/charts/"
  chart      = "nats"
}
