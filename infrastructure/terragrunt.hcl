include "root" {
  path = "./root.hcl"
}

dependency "cloudnative_pg" {
  config_path = "./modules/cloudnative-pg"
  skip_outputs = true
}

dependency "cert_manager" {
  config_path = "./modules/cert-manager"
  skip_outputs = true
}

remote_state {
  backend = "kubernetes"
  config = {
    secret_suffix    = "root"
    load_config_file = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

