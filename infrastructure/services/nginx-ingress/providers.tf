provider "kubernetes" {
  config_path = var.kube_config_path
  experiments {
    manifest_resource = true
  }
}

provider "helm" {
  kubernetes {
    config_path = var.kube_config_path
  }
}
