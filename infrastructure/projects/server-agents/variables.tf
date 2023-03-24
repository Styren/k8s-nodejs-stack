variable "servers" {
  type = list(object({
    name      = string
    hostname  = string
    server_ip = string
  }))
}


variable "namespace" {}
