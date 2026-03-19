# Certificates and DNS

ACM certificate provisioning and Route53 DNS record management for HTTPS access.

## Why HTTPS is Required for BRMS

BRMS uses browser APIs that require secure contexts:
- **Web Crypto API** — cryptographic operations
- **Service Workers** — offline support and caching

Without HTTPS, BRMS displays a **blank page**. This is enforced at the [variable validation](variable-system.md) level.

## Two Ways to Provide HTTPS

### Option 1: Route53 Zone ID (auto-managed)

Provide `route53_zone_id` and the module handles everything:

1. Creates ACM certificate for the domain
2. Creates DNS validation records
3. Validates the certificate
4. Creates an A record (alias) pointing to the ALB

```hcl
brms = {
  domain          = "rules.example.com"
  route53_zone_id = "Z0123456789ABCDEF"
  # certificate_arn is auto-created
}
```

### Option 2: Existing Certificate ARN

Bring your own validated ACM certificate:

```hcl
brms = {
  domain          = "rules.example.com"
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
  # No Route53 management — you handle DNS
}
```

## Resources Created (Route53 mode)

### For BRMS (always, if route53_zone_id provided)

| Resource | Purpose |
|----------|---------|
| `aws_acm_certificate.brms` | Certificate for BRMS domain |
| `aws_route53_record.brms_validation` | DNS records for certificate validation |
| `aws_acm_certificate_validation.brms` | Waits for certificate to be valid |
| `aws_route53_record.brms_alias` | A record (alias) → BRMS ALB |

### For Agent (conditional)

Same pattern, but only created if:
- Agent is enabled
- Agent has a domain configured
- Agent has a route53_zone_id

Agent HTTPS is **optional** — HTTP-only works fine for the Agent.

## ALB Listener Configuration

### BRMS (HTTPS required)

| Listener | Port | Action |
|----------|------|--------|
| HTTP | 80 | Redirect to HTTPS (301) |
| HTTPS | 443 | Forward to target group |

SSL Policy: `ELBSecurityPolicy-TLS13-1-2-2021-06` (TLS 1.3)

### Agent (HTTPS optional)

| Scenario | Port 80 | Port 443 |
|----------|---------|----------|
| With certificate | Redirect to HTTPS | Forward to target group |
| Without certificate | Forward to target group | Not created |

## Certificate Resolution Logic

```hcl
local.brms_certificate_arn = (
  var.brms.certificate_arn != null
    ? var.brms.certificate_arn
    : aws_acm_certificate.brms[0].arn
)
```

Priority: user-provided ARN > auto-created certificate.

## DNS Record Details

### Alias Record

```hcl
resource "aws_route53_record" "brms_alias" {
  zone_id = var.brms.route53_zone_id
  name    = var.brms.domain
  type    = "A"

  alias {
    name                   = aws_lb.brms[0].dns_name
    zone_id                = aws_lb.brms[0].zone_id
    evaluate_target_health = true
  }
}
```

The `evaluate_target_health = true` means Route53 health checks monitor the ALB.
