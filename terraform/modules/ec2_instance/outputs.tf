output "instance_id" {
  description = "The ID of the instance."
  value       = var.public ? aws_instance.public[0].id : aws_instance.private[0].id
}

output "instance_public_ip" {
  description = "The public IP address assigned to the instance."
  value       = var.public ? aws_instance.public[0].public_ip : aws_instance.private[0].public_ip
}

