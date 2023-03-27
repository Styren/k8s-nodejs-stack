remote_state {
  backend = "kubernetes"
  config = {
    secret_suffix    = "${replace(path_relative_to_include(), "/", "-")}"
    load_config_file = true
    config_path      = "${get_parent_terragrunt_dir()}/config"
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
  domain              = "x.symbiosis.host"
  container_registry              = "ghcr.io"

  github_username              = "Styren"
}

generate "provider" {
  path = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "kubernetes" {
  config_path    = "${get_parent_terragrunt_dir()}/config"
}

provider "helm" {
  kubernetes {
    config_path    = "${get_parent_terragrunt_dir()}/config"
  }
}
  EOF
}
