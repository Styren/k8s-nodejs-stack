# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
terraform {
  backend "kubernetes" {
    load_config_file = true
    secret_suffix    = "nginx-ingress"
  }
}
