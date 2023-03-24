variable "namespace" {
  default = "default"
}

variable "spring_profile" {
  default = "staging"
}

variable "gcp_project_id" {}

variable "postgresql_user" {}

variable "postgresql_host" {}

variable "postgresql_password" {}

variable "postgresql_port" {}

variable "firebase_api_key" {}

variable "postgresql_database" {
  default = "postgres"
}

variable "additional_backend_config" {
  type    = map(any)
  default = {}
}

variable "additional_backend_secrets" {
  type      = map(any)
  sensitive = true
  default   = {}
}
