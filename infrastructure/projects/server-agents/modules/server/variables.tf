variable "namespace" {}

variable "name" {}
variable "hostname" {}
variable "server_ip" {}

variable "vault_ca_secret_ref" {
  type = object({
    name = string
    key  = string
  })
}
