terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    grafana = {
      source = "grafana/grafana"
    }
  }
  required_version = ">= 0.14"
}
