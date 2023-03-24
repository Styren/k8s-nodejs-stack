output "external_port" {
  value = kubernetes_service.postgresql.spec.0.port.0.node_port
}

output "internal_name" {
  value = "${kubernetes_service.postgresql.metadata.0.name}.${kubernetes_service.postgresql.metadata.0.namespace}"
}

output "internal_port" {
  value = kubernetes_service.postgresql.spec.0.port.0.port
}

output "admin_password" {
  value     = random_password.postgresql.result
  sensitive = true
}
