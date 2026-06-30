locals {
  create_brms_certificate  = local.create_brms && var.brms.route53_zone_id != null && !var.brms.alb_http_only
  create_agent_certificate = local.create_agent && var.agent.domain != null && var.agent.route53_zone_id != null && !var.agent.alb_http_only

  # TLS terminates on the ALB unless alb_http_only is set (then a trusted edge such as CloudFront terminates it).
  brms_use_tls  = var.brms != null ? !var.brms.alb_http_only : false
  agent_use_tls = var.agent != null ? (!var.agent.alb_http_only && local.agent_certificate_arn != null) : false

  brms_certificate_arn = var.brms != null ? (
    var.brms.certificate_arn != null ? var.brms.certificate_arn :
    local.create_brms_certificate ? aws_acm_certificate.brms[0].arn :
    null
  ) : null

  agent_certificate_arn = var.agent != null ? (
    var.agent.certificate_arn != null ? var.agent.certificate_arn :
    local.create_agent_certificate ? aws_acm_certificate.agent[0].arn :
    null
  ) : null
}

resource "aws_acm_certificate" "brms" {
  count = local.create_brms_certificate ? 1 : 0

  domain_name       = var.brms.domain
  validation_method = "DNS"

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-brms-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "brms_validation" {
  for_each = local.create_brms_certificate ? {
    for dvo in aws_acm_certificate.brms[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.brms.route53_zone_id
}

resource "aws_acm_certificate_validation" "brms" {
  count = local.create_brms_certificate ? 1 : 0

  certificate_arn         = aws_acm_certificate.brms[0].arn
  validation_record_fqdns = [for record in aws_route53_record.brms_validation : record.fqdn]
}

resource "aws_route53_record" "brms_alias" {
  count = local.create_brms_certificate ? 1 : 0

  zone_id = var.brms.route53_zone_id
  name    = var.brms.domain
  type    = "A"

  alias {
    name                   = aws_lb.brms[0].dns_name
    zone_id                = aws_lb.brms[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "agent" {
  count = local.create_agent_certificate ? 1 : 0

  domain_name       = var.agent.domain
  validation_method = "DNS"

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-agent-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "agent_validation" {
  for_each = local.create_agent_certificate ? {
    for dvo in aws_acm_certificate.agent[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.agent.route53_zone_id
}

resource "aws_acm_certificate_validation" "agent" {
  count = local.create_agent_certificate ? 1 : 0

  certificate_arn         = aws_acm_certificate.agent[0].arn
  validation_record_fqdns = [for record in aws_route53_record.agent_validation : record.fqdn]
}

resource "aws_route53_record" "agent_alias" {
  count = local.create_agent_certificate ? 1 : 0

  zone_id = var.agent.route53_zone_id
  name    = var.agent.domain
  type    = "A"

  alias {
    name                   = aws_lb.agent[0].dns_name
    zone_id                = aws_lb.agent[0].zone_id
    evaluate_target_health = true
  }
}
