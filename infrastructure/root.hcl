remote_state {
  backend = "kubernetes"
  config = {
    secret_suffix    = "${replace(path_relative_to_include(), "/", "-")}"
    load_config_file = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  ingress_annotations = {
    "acme.cert-manager.io/http01-edit-in-place" : "true"
    "kubernetes.io/ingress.class" : "nginx"
    "kubernetes.io/tls-acme" : "true"
    "cert-manager.io/cluster-issuer" : "letsencrypt"
  }
  container_registry              = "ghcr.io"

  domain              = "ENTER_YOUR_DOMAIN_NAME_HERE"
}

generate "provider" {
  path = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "kubernetes" {
}

provider "helm" {
  kubernetes {
  }
}
  EOF
}
