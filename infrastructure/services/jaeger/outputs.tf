output "internal_name" {
  value = "jaeger-collector-headless.${var.namespace}"
}

output "internal_port" {
  value = 14250
}
