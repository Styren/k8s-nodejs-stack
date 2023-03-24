include "root" {
  path = "./root.hcl"
}

dependency "jaeger" {
  config_path = "./services/jaeger"
  skip_outputs = true
}

dependency "cloudnative_pg" {
  config_path = "./services/cloudnative-pg"
  skip_outputs = true
}

remote_state {
  backend = "kubernetes"
  config = {
    secret_suffix    = "root"
    load_config_file = true
    config_path      = "${get_parent_terragrunt_dir()}/config"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

