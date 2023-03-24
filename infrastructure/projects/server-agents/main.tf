locals {
  vault_ca_secret_name = "vault-intermediate-ca"
  vault_ca_secret_key  = "ca.crt"
}
module "agent" {
  for_each = { for _, server in var.servers : server.name  => server }

  source    = "./modules/server"
  namespace = var.namespace

  name      = each.value.name
  hostname  = each.value.hostname
  server_ip = each.value.server_ip

  vault_ca_secret_ref = {
    name = local.vault_ca_secret_name
    key  = local.vault_ca_secret_key
  }
}

data "vault_policy_document" "agent" {
  rule {
    path         = "pki/intermediate-pki/*"
    capabilities = ["update", "create"]
  }
}

data "vault_generic_secret" "vault_ca" {
  path = "pki/intermediate-pki/cert/ca"
}

resource "kubernetes_secret" "vault_ca" {
  metadata {
    name      = "vault-intermediate-ca"
    namespace = var.namespace
  }

  data = {
    (local.vault_ca_secret_key) : data.vault_generic_secret.vault_ca.data["certificate"]
  }
}

resource "vault_policy" "agent" {
  name   = "server-agent-${var.namespace}"
  policy = data.vault_policy_document.agent.hcl
}

resource "vault_pki_secret_backend_role" "agent" {
  backend       = "pki/intermediate-pki"
  name          = "server-agent-${var.namespace}"
  ttl           = 3600
  allow_ip_sans = true
  key_type      = "rsa"
  key_bits      = 4096
  allowed_domains = [
    "server-agent-${var.namespace}-*",
    "server-agent-${var.namespace}",
    "*.symbiosis.host",
  ]
  allow_subdomains   = true
  allow_bare_domains = true
  allow_glob_domains = true
  generate_lease     = true
  key_usage = [
    "DigitalSignature",
    "KeyAgreement",
    "KeyEncipherment",
    "CertSign"
  ]
  ext_key_usage = [
    "ClientAuth",
    "ServerAuth"
  ]
}

