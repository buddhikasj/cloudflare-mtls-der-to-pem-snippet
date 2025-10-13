
resource "cloudflare_snippet" "der_to_pem" {
  zone_id      = var.cloudflare_zone_id
  snippet_name = "der_to_pem"
  files = [
    {
      name    = "main.js"
      content = <<-EOT
        // Function that converts the base64 encoded DER certificate to PEM format
function toPem(base64) {
  let pem = '-----BEGIN CERTIFICATE-----\n'
  // Add a new line after every 64 characters
  for (let i = 0; i < base64.length; i += 64) {
    pem += base64.slice(i, i + 64) + '\n'
  }
  pem += '-----END CERTIFICATE-----\n'
  return pem
}

// Cloudflare Snippet export
export default {
  async fetch(request) {
    // Create a headers object from the request headers
    const headers = new Headers(request.headers)
   
    // Get the base64 encoded DER certificate and subject
    const cert = headers.get('cf-client-cert-der-base64')
   
    // Only process if certificate is present
    if (!cert) {
      return fetch(request)
    }
   
    // Convert the base64 encoded DER certificate to PEM format
    const pem = toPem(cert)
   
    // Set the X-Forwarded-Client-Cert header with the PEM certificate
    headers.set('${var.pem_header_name}',  btoa(pem))

    
    // Clone the request with the updated headers
    const requestClone = new Request(request, { headers: headers })
   
    // Fetch the request
    return fetch(requestClone)
  }
}
      EOT
    }
  ]
  metadata = {
    main_module = "main.js"
  }
}