resource "aws_route53_zone" "main" {
  name    = "aws-prod-lab.click"
  comment = "HostedZone created by Route53 Registrar"
}

resource "aws_acm_certificate" "web" {
  domain_name       = "aws-prod-lab.click"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_validation" {
  zone_id = aws_route53_zone.main.zone_id
  name    = tolist(aws_acm_certificate.web.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.web.domain_validation_options)[0].resource_record_type
  ttl     = 300
  records = [
    tolist(aws_acm_certificate.web.domain_validation_options)[0].resource_record_value
  ]
}

resource "aws_acm_certificate_validation" "web" {
  certificate_arn = aws_acm_certificate.web.arn

  validation_record_fqdns = [
    aws_route53_record.acm_validation.fqdn
  ]
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "aws-prod-lab.click"
  type    = "A"

  alias {
    name                   = "dualstack.${aws_lb.web.dns_name}"
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}