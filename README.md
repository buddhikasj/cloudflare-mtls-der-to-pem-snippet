# Cloudflare DER to PEM Certificate Converter Snippet

This Terraform configuration deploys a Cloudflare Snippet that converts client certificates from DER format (base64 encoded) to PEM format and forwards them to your origin server via a custom header.

## Overview

When Cloudflare performs mTLS (mutual TLS) authentication, it provides the client certificate in DER format via the `cf-client-cert-der-base64` header. This snippet:

1. Intercepts incoming requests matching specific criteria
2. Extracts the DER-encoded client certificate
3. Converts it to PEM format
4. Forwards the PEM certificate to your origin in a custom header (default: `X-Forwarded-Client-Cert`)

## Features

- ✅ Automatic DER to PEM certificate conversion
- ✅ Configurable header name for forwarding certificates
- ✅ Flexible rule expressions for targeting specific traffic
- ✅ Base64 encoding of PEM certificate for safe transport
- ✅ Validation for snippet descriptions

## Prerequisites

- Terraform >= 1.0.0
- Cloudflare account with API access
- Cloudflare zone ID
- Cloudflare API token with the following permissions:
  - Zone > Snippets > Edit
  - Zone > Snippet Rules > Edit

## File Structure

```
.
├── README.md              # This file
├── versions.tf            # Terraform and provider version requirements
├── variables.tf           # Input variables
├── snippet.tf             # Cloudflare Snippet resource (JavaScript code)
├── rules_snippet.tf       # Snippet rule configuration
├── terraform.tfvars       # Variable values (gitignored)
└── .gitignore            # Git ignore patterns
```

## Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `cloudflare_api_key` | string | Yes | - | Cloudflare API token |
| `cloudflare_zone_id` | string | Yes | - | Cloudflare Zone ID |
| `pem_header_name` | string | No | `X-Forwarded-Client-Cert` | Header name for forwarding PEM certificate |
| `expression` | string | No | `ip.src eq 1.1.1.1` | Cloudflare rule expression for when to execute snippet |
| `snippet_description` | string | No | `Execute_der_to_pem_when_IP_address_is_1_1_1_1` | Description for the snippet rule (alphanumeric and underscore only) |

## Setup Instructions

### 1. Clone or Navigate to This Directory

```bash
cd terraform/der_to_pem_snippet
```

### 2. Create `terraform.tfvars`

Create a `terraform.tfvars` file with your configuration:

```hcl
cloudflare_api_key = "your-cloudflare-api-token"
cloudflare_zone_id = "your-zone-id"

# Optional: Customize these values
expression = "http.host eq \"example.com\" and cf.edge.server_port eq 443"
pem_header_name = "X-Forwarded-Client-Cert"
snippet_description = "Convert_DER_to_PEM_for_mTLS"
```

**Note:** The `terraform.tfvars` file is gitignored to protect sensitive information.

### 3. Set Environment Variable (Alternative)

Instead of using `terraform.tfvars`, you can set the API key as an environment variable:

```bash
export TF_VAR_cloudflare_api_key="your-cloudflare-api-token"
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Review the Plan

```bash
terraform plan
```

### 6. Apply the Configuration

```bash
terraform apply
```

## Rule Expression Examples

The `expression` variable uses Cloudflare's rule expression language. Here are some examples:

### Match specific hostname and port
```hcl
expression = "http.host eq \"api.example.com\" and cf.edge.server_port eq 443"
```

### Match wildcard hostname
```hcl
expression = "http.host wildcard \"*.example.com\" and cf.edge.server_port eq 443"
```

### Match specific IP address
```hcl
expression = "ip.src eq 1.1.1.1"
```

### Match IP range
```hcl
expression = "ip.src in {192.168.1.0/24}"
```

### Complex expression
```hcl
expression = "(http.host eq \"api.example.com\" or http.host eq \"api2.example.com\") and cf.edge.server_port eq 443"
```

## How It Works

### Certificate Conversion Process

1. **Request arrives** at Cloudflare edge with client certificate
2. **Cloudflare mTLS** validates the certificate and adds `cf-client-cert-der-base64` header
3. **Snippet executes** based on the rule expression
4. **JavaScript function** `toPem()` converts DER to PEM format:
   - Adds PEM header: `-----BEGIN CERTIFICATE-----`
   - Splits base64 string into 64-character lines
   - Adds PEM footer: `-----END CERTIFICATE-----`
5. **PEM certificate** is base64 encoded and set in custom header
6. **Request forwarded** to origin with the PEM certificate

### JavaScript Snippet

The snippet uses Cloudflare's Workers runtime and:
- Reads the `cf-client-cert-der-base64` header
- Converts it to PEM format with proper line breaks
- Base64 encodes the PEM certificate
- Sets it in the configured header name
- Forwards the modified request to the origin

## Origin Server Integration

Your origin server will receive the PEM certificate in the configured header (default: `X-Forwarded-Client-Cert`). The certificate is base64 encoded, so you'll need to decode it:

### Example: Node.js/Express

```javascript
app.use((req, res, next) => {
  const pemCert = req.headers['x-forwarded-client-cert'];
  if (pemCert) {
    const decodedPem = Buffer.from(pemCert, 'base64').toString('utf-8');
    console.log('Client Certificate:', decodedPem);
    // Process the certificate...
  }
  next();
});
```

### Example: Python/Flask

```python
import base64

@app.before_request
def process_client_cert():
    pem_cert = request.headers.get('X-Forwarded-Client-Cert')
    if pem_cert:
        decoded_pem = base64.b64decode(pem_cert).decode('utf-8')
        print(f'Client Certificate: {decoded_pem}')
        # Process the certificate...
```

## Validation

The `snippet_description` variable has validation to ensure it only contains:
- Lowercase letters (a-z)
- Uppercase letters (A-Z)
- Numbers (0-9)
- Underscores (_)

This matches Cloudflare's requirements for snippet descriptions.

## Cleanup

To remove all resources created by this configuration:

```bash
terraform destroy
```

## Troubleshooting

### Snippet not executing
- Verify the rule expression matches your traffic
- Check that the snippet is enabled in Cloudflare dashboard
- Ensure mTLS is configured on your zone

### Certificate not forwarded
- Verify the `cf-client-cert-der-base64` header is present (requires mTLS)
- Check origin server logs for the custom header
- Ensure the header name matches your configuration

### Terraform errors
- Run `terraform fmt` to fix formatting issues
- Verify your API token has the required permissions
- Check that the zone ID is correct

## Security Considerations

- ⚠️ **Never commit `terraform.tfvars`** - it contains sensitive API tokens
- ⚠️ **Use environment variables** for CI/CD pipelines
- ⚠️ **Rotate API tokens** regularly
- ⚠️ **Limit API token permissions** to only what's needed
- ⚠️ **Validate certificates** at your origin server

## Additional Resources

- [Cloudflare Snippets Documentation](https://developers.cloudflare.com/rules/snippets/)
- [Cloudflare Rule Expressions](https://developers.cloudflare.com/ruleset-engine/rules-language/)
- [Cloudflare mTLS Documentation](https://developers.cloudflare.com/ssl/client-certificates/)
- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)

## License

This configuration is provided as-is for use with Cloudflare infrastructure.

## Support

For issues or questions:
1. Check Cloudflare documentation
2. Review Terraform plan output
3. Verify API token permissions
4. Check Cloudflare dashboard for snippet status
