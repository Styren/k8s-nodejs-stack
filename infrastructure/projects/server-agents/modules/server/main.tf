locals {
  auth_secret_name = "server-agent-${var.name}-basic-auth"
  labels = {
    app      = "server-agent"
    instance = var.name
  }
}

data "kubernetes_secret" "server" {
  metadata {
    name      = local.auth_secret_name
    namespace = var.namespace
  }
}

resource "kubernetes_service" "server" {
  metadata {
    name      = "server-agent-server-${var.name}"
    namespace = var.namespace
    labels    = local.labels
    annotations = {
      "hostname" = var.hostname
    }
  }

  spec {
    cluster_ip = "None"

    port {
      name     = "libvirt-metrics"
      port     = 9177
      protocol = "TCP"
    }

    port {
      name     = "haproxy-metrics"
      port     = 8404
      protocol = "TCP"
    }

    port {
      name     = "service"
      port     = 8081
      protocol = "TCP"
    }

    port {
      name     = "ceph-metrics"
      port     = 9128
      protocol = "TCP"
    }

  }
}

resource "kubernetes_endpoints" "server" {
  metadata {
    name      = "server-agent-server-${var.name}"
    namespace = var.namespace
    labels    = local.labels
  }

  subset {
    address {
      ip = var.server_ip
    }

    // Endpoint connects all service ports
    dynamic "port" {
      for_each = kubernetes_service.server.spec.0.port

      content {
        name     = port.value.name
        port     = port.value.port
        protocol = port.value.protocol
      }
    }
  }
}


resource "kubernetes_manifest" "agent_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "server-agent-${var.name}"
      namespace = var.namespace
      labels = {
        prometheus = "kube-prometheus"
      }
    }
    spec = {
      namespaceSelector = {
        matchNames = [
          var.namespace
        ]
      }
      endpoints = [
        {
          // TODO add auth
          path = "/metrics"
          port = "libvirt-metrics"
        },
        {
          path = "/metrics"
          port = "ceph-metrics"
        },
        {
          path = "/metrics"
          port = "haproxy-metrics"
          basicAuth = {
            username = {
              name = local.auth_secret_name
              key  = "username",
            }
            password = {
              name = local.auth_secret_name
              key  = "password",
            }
          }
        },
        {
          path   = "/actuator/prometheus"
          scheme = "https"
          tlsConfig = {
            serverName = var.hostname
            ca = {
              secret = {
                name = var.vault_ca_secret_ref.name
                key  = var.vault_ca_secret_ref.key
              }
            }
          }
          port = "service"
          basicAuth = {
            username = {
              name = local.auth_secret_name
              key  = "username",
            }
            password = {
              name = local.auth_secret_name
              key  = "password",
            }
          }
        },
      ]
      selector = {
        matchLabels = local.labels
      }
    }
  }
}

