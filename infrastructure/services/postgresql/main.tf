resource "random_password" "postgresql" {
  length  = 16
  special = false
}

resource "kubernetes_persistent_volume_claim" "postgresql" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.storage_capacity
      }
    }
  }
}

resource "kubernetes_stateful_set" "postgresql" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      app = var.name
    }
  }

  spec {
    selector {
      match_labels = {
        app = var.name
      }
    }

    service_name = var.name

    update_strategy {
      type = "RollingUpdate"
    }

    template {
      metadata {
        labels = {
          app = var.name
        }
      }

      spec {
        volume {
          name = var.postgresql_volume_name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgresql.metadata.0.name
          }
        }

        container {
          image = var.image
          name  = var.name

          resources {
            limits = {
              cpu    = var.postgresql_cpu_limit
              memory = var.postgresql_memory_limit
            }

            requests = {
              cpu    = var.postgresql_cpu_request
              memory = var.postgresql_memory_request
            }
          }

          volume_mount {
            name       = var.postgresql_volume_name
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "postgres"
          }

          env {
            name  = "POSTGRES_USER"
            value = var.postgresql_user
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = random_password.postgresql.result
          }

          port {
            container_port = 5432
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgresql" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      app = var.name
    }
  }
  spec {
    type = "NodePort"
    selector = {
      app = kubernetes_stateful_set.postgresql.metadata.0.labels.app
    }
    port {
      port        = 5432
      target_port = 5432
    }
  }
}

resource "grafana_data_source" "postgresql" {
  type          = "postgres"
  name          = "${var.name}-${var.namespace}"
  url           = "${var.name}.${var.namespace}:5432"
  database_name = "postgres"
  username      = var.postgresql_user
  secure_json_data {
    password = random_password.postgresql.result
  }
  json_data {
    postgres_version = 1200
    timescaledb      = true
    ssl_mode         = "disable"
  }
}
