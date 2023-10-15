# output.tf

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of the created subnets"
  value       = aws_subnet.subnet.*.id
}

output "private_dns_zone_id" {
  description = "ID of the private Route53 DNS zone"
  value       = aws_route53_zone.private_zone.id
}

output "private_dns_zone_name" {
  description = "Name of the private Route53 DNS zone"
  value       = aws_route53_zone.private_zone.name
}

output "base_security_group_id" {
  value = aws_security_group.empty_sg.id
}