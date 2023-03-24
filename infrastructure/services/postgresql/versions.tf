terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 1.20.0"
    }
  }
  required_version = ">= 0.14"
}
