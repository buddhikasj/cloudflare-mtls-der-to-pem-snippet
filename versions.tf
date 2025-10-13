terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "> 5"
    }
  }
  required_version = ">= 1.0.0"
}

provider "cloudflare" {
  # api_token can be set via environment variable CLOUDFLARE_API_TOKEN
  # email and api_key are deprecated, prefer api_token

  # Uncomment and use variables or environment variables as needed
  api_token = var.cloudflare_api_key
}