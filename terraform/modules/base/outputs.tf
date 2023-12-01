# output.tf

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the created subnets"
  value       = aws_subnet.public_subnet.*.id
}

output "private_subnet_ids" {
  description = "IDs of the created subnets"
  value       = aws_subnet.private_subnet.*.id
}

output "private_dns_zone_id" {
  description = "ID of the private Route53 DNS zone"
  value       = aws_route53_zone.private_zone.id
}

output "lb_target_group_id" {
  description = "ID of the lb target group"
  value       = aws_lb_target_group.k8s_tg.arn
}

output "lb_dns_name" {
  description = "DNS of the lb"
  value       = aws_lb.k8s_lb.dns_name
}

output "ca_cert" {
  value = {
    private_key_pem = tls_private_key.ca_key.private_key_pem
    cert_pem        = tls_self_signed_cert.ca_cert.cert_pem
  }
  sensitive = true
}

output "private_dns_zone_name" {
  description = "Name of the private Route53 DNS zone"
  value       = aws_route53_zone.private_zone.name
}

output "base_security_group_id" {
  value = aws_security_group.empty_sg.id
}