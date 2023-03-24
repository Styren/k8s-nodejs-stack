variable "postgresql_user" {
  description = "Root postgresql user"
}

variable "storage_capacity" {}

variable "name" {
  default = "postgresql"
}

variable "postgresql_volume_name" {
  default = "postgresql"
}

variable "image" {
  default = "timescale/timescaledb:1.7.4-pg12"
}

variable "namespace" {
  default = "default"
}

variable "postgresql_cpu_limit" {
  default = "400m"
}

variable "postgresql_memory_limit" {
  default = "1Gi"
}

variable "postgresql_cpu_request" {
  default = "100m"
}

variable "postgresql_memory_request" {
  default = "128Mi"
}
