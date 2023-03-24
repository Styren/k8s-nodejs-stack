locals {
  name = "backend"
  labels = {
    app = "backend"
  }
  google_credentials_path = "/etc/google/credentials.json"
}


resource "google_service_account" "backend" {
  account_id   = "stim-backend"
  display_name = "Symbiosis Backend"
  project      = var.gcp_project_id
}

resource "google_service_account_key" "backend" {
  service_account_id = google_service_account.backend.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "pubsub_iam_role" {
  project = var.gcp_project_id
  role    = "roles/pubsub.editor"
  member  = "serviceAccount:${google_service_account.backend.email}"
}

resource "kubernetes_secret" "service_account_json" {
  metadata {
    name      = "backend-service-account"
    namespace = var.namespace
  }

  binary_data = {
    "FIREBASE_SERVICE_ACCOUNT_JSON" : google_service_account_key.backend.private_key
  }
}

resource "vault_mount" "backend_kvv2" {
  path        = "backend-kv/${var.namespace}"
  type        = "kv-v2"
  description = "Backend kv mount for ${var.namespace} environment"
}

resource "vault_pki_secret_backend_role" "backend" {
  backend       = "pki/intermediate-pki"
  name          = "backend-${var.namespace}"
  ttl           = 3600
  allow_ip_sans = true
  key_type      = "rsa"
  key_bits      = 4096
  allowed_domains = [
    "backend-*",
  ]
  allow_subdomains   = true
  allow_bare_domains = true
  allow_glob_domains = true
  generate_lease     = true
  key_usage = [
    "DigitalSignature",
    "KeyAgreement",
    "KeyEncipherment",
  ]
}

resource "kubernetes_manifest" "service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "backend"
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
          path = "/actuator/prometheus"
          port = "service"
        },
      ]
      selector = {
        matchLabels = local.labels
      }
    }
  }
}

resource "random_password" "aes_secret" {
  length  = 16
  special = false
}

resource "random_password" "truststore_password" {
  length  = 16
  special = false
}

data "kubernetes_service_account_v1" "default" {
  metadata {
    name      = "default"
    namespace = var.namespace
  }
}

resource "kubernetes_service_account_v1" "backend" {
  metadata {
    name      = "backend"
    namespace = var.namespace
  }

  image_pull_secret {
    name = data.kubernetes_service_account_v1.default.image_pull_secret.0.name
  }
}

resource "kubernetes_role" "backend" {
  metadata {
    name      = "backend"
    namespace = var.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch", "create"]
  }
}

resource "kubernetes_role_binding" "backend" {
  metadata {
    name      = "backend"
    namespace = var.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.backend.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.backend.metadata.0.name
    namespace = var.namespace
  }
}


resource "vault_token_auth_backend_role" "control_plane" {
  role_name              = "control-plane-${var.namespace}"
  allowed_policies       = [vault_policy.control_plane.name]
  allowed_entity_aliases = ["control-plane/*"]
  orphan                 = true
}

resource "vault_token_auth_backend_role" "worker" {
  role_name              = "worker-${var.namespace}"
  allowed_policies       = [vault_policy.worker.name]
  allowed_entity_aliases = ["worker/*"]
  orphan                 = true
}

data "vault_policy_document" "backend" {
  rule {
    path         = "/identity/*"
    capabilities = ["create", "read", "update", "list", "delete"]
  }
  rule {
    path         = "sys/mounts/backend-projects/${var.namespace}/*"
    capabilities = ["create", "read", "update", "list", "delete"]
  }
  rule {
    path         = "backend-projects/${var.namespace}/*"
    capabilities = ["create", "read", "update", "list", "delete"]
  }
  rule {
    path         = "${vault_mount.backend_kvv2.path}/*"
    capabilities = ["create", "read", "update", "list", "delete"]
  }
  rule {
    path         = "pki/intermediate-pki/*"
    capabilities = ["update", "create"]
  }
  rule {
    path         = "/auth/token"
    capabilities = ["create", "update"]
  }
  rule {
    path         = "/auth/token/*"
    capabilities = ["create", "update"]
  }
}

resource "vault_policy" "backend" {
  name   = "backend-${var.namespace}"
  policy = data.vault_policy_document.backend.hcl
}

data "vault_policy_document" "control_plane" {
  rule {
    path         = "${vault_mount.backend_kvv2.path}/cluster/{{identity.entity.metadata.cluster_id}}/pki/*"
    capabilities = ["read"]
  }
  rule {
    path         = "${vault_mount.backend_kvv2.path}/cluster/{{identity.entity.metadata.cluster_id}}/pki/node/{{identity.entity.metadata.node_name}}/*"
    capabilities = ["read"]
  }
  rule {
    path         = "${vault_mount.backend_kvv2.path}/cluster/{{identity.entity.metadata.cluster_id}}/configuration"
    capabilities = ["read"]
  }
  rule {
    path         = "${vault_mount.backend_kvv2.path}/data/cluster/{{identity.entity.metadata.cluster_id}}/pki/*"
    capabilities = ["read"]
  }
  rule {
    path         = "${vault_mount.backend_kvv2.path}/data/cluster/{{identity.entity.metadata.cluster_id}}/pki/node/{{identity.entity.metadata.node_name}}/*"
    capabilities = ["read"]
  }
  rule {
    path         = "${vault_mount.backend_kvv2.path}/data/cluster/{{identity.entity.metadata.cluster_id}}/configuration"
    capabilities = ["read"]
  }
}

resource "vault_policy" "control_plane" {
  name   = "control-plane-${var.namespace}"
  policy = data.vault_policy_document.control_plane.hcl
}

data "vault_policy_document" "worker" {
  rule {
    path         = "${vault_mount.backend_kvv2.path}/data/cluster/{{identity.entity.metadata.cluster_id}}/pki/*"
    capabilities = ["read"]
  }
  rule {
    path         = "${vault_mount.backend_kvv2.path}/cluster/{{identity.entity.metadata.cluster_id}}/pki/*"
    capabilities = ["read"]
  }
  rule {
    path         = "${vault_mount.backend_kvv2.path}/cluster/{{identity.entity.metadata.cluster_id}}/pki/node/{{identity.entity.metadata.node_name}}/*"
    capabilities = ["read"]
  }
  rule {
    path         = "${vault_mount.backend_kvv2.path}/data/cluster/{{identity.entity.metadata.cluster_id}}/pki/node/{{identity.entity.metadata.node_name}}/*"
    capabilities = ["read"]
  }
  rule {
    path         = "${vault_mount.backend_kvv2.path}/data/cluster/{{identity.entity.metadata.cluster_id}}/configuration"
    capabilities = ["read"]
  }
}

resource "vault_policy" "worker" {
  name   = "worker-${var.namespace}"
  policy = data.vault_policy_document.worker.hcl
}

data "vault_auth_backend" "token" {
  path = "token"
}

data "kubernetes_secret" "send_in_blue" {
  metadata {
    name      = "send-in-blue"
    namespace = var.namespace
  }
}

data "kubernetes_secret" "symbiosis_github_app" {
  metadata {
    name      = "symbiosis-github-app"
    namespace = var.namespace
  }
}

resource "kubernetes_config_map" "backend_configuration" {
  metadata {
    name      = "backend-configuration"
    namespace = var.namespace
  }

  data = merge({
    "spring_profiles_active" : var.spring_profile
    "JVM_OPTS" : "-Xms256k -Xmx32m -XX:+UseSerialGC -XX:MaxJavaStackTraceDepth=64"
    "SPRING_DATASOURCE_URL" : "jdbc:postgresql://${var.postgresql_host}:${var.postgresql_port}/${var.postgresql_database}"
    "SYMBIOSIS_VAULT_KV_PATH" : vault_mount.backend_kvv2.path
    "SYMBIOSIS_VAULT_TOKEN_MOUNT_ACCESSOR" : data.vault_auth_backend.token.accessor
    "SYMBIOSIS_VAULT_CONTROL_PLANE_POLICY" : vault_policy.control_plane.name
    "SYMBIOSIS_VAULT_WORKER_POLICY" : vault_policy.worker.name
    "SYMBIOSIS_VAULT_PKI_ROLE" : vault_pki_secret_backend_role.backend.name
    "FIREBASE_PROJECT_ID" : var.gcp_project_id
    "SYMBIOSIS_VAULT_CONTROL_PLANE_ROLE" : vault_token_auth_backend_role.control_plane.role_name
    "SYMBIOSIS_VAULT_WORKER_ROLE" : vault_token_auth_backend_role.worker.role_name
    "SYMBIOSIS_PROJECT_KUBERNETES_PREVIEW_CLI_IMAGE" : "registry.symbiosis.host/preview-cli:v0.0.15"
  }, var.additional_backend_config)
}

resource "kubernetes_secret" "backend_configuration" {
  metadata {
    name      = "backend-configuration"
    namespace = var.namespace
  }

  data = merge({
    "SPRING_DATASOURCE_USERNAME" : var.postgresql_user
    "SPRING_DATASOURCE_PASSWORD" : var.postgresql_password
    "SYMBIOSIS_AES_SECRET" : random_password.aes_secret.result
    "TRUSTSTORE_PASSWORD" : random_password.truststore_password.result
    "GOOGLE_APPLICATION_CREDENTIALS" : local.google_credentials_path
    "SEND_IN_BLUE_API_KEY" : data.kubernetes_secret.send_in_blue.data.api_key
    "GITHUB_APP_PEM" : data.kubernetes_secret.symbiosis_github_app.data.github_app_key
    "FIREBASE_API_KEY" : var.firebase_api_key
  }, var.additional_backend_secrets)
}


resource "vault_kubernetes_auth_backend_role" "backend" {
  backend                          = "kubernetes"
  role_name                        = "backend-${var.namespace}"
  bound_service_account_names      = [kubernetes_service_account_v1.backend.metadata.0.name]
  bound_service_account_namespaces = [var.namespace]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.backend.name, vault_policy.control_plane.name, vault_policy.worker.name]
}
