variable "cloudflare_api_key" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}

variable "pem_header_name" {
  type    = string
  default = "X-Forwarded-Client-Cert"
}


variable "expression" {
  type    = string
  default = "ip.src eq 1.1.1.1"
}

variable "snippet_description" {
  type = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_]*$", var.snippet_description))
    error_message = "snippet_description can only contain the characters a-z,0-9, and _"
  }
  default = "Execute_der_to_pem_when_IP_address_is_1_1_1_1"
}
  