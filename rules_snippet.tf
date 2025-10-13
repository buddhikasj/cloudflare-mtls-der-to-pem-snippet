resource "cloudflare_snippet_rules" "der_to_pem" {
  zone_id = var.cloudflare_zone_id
  rules = [{
    expression   = var.expression
    snippet_name = "der_to_pem"
    description  = var.snippet_description
    enabled      = true
  }]
}