terraform {
  required_providers {
    github = {
      source = "hashicorp/github"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 1.20.0"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.19.0"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
  }
  required_version = ">= 0.14"
}
