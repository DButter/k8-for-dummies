variable "vpc_id" {
  description = "The ID of the VPC in which to launch the instance."
  type        = string
}

variable "template_configs" {
  description = "A list of template configurations with filenames and variables"
  type = list(object({
    filename : string
    template_vars : map(string)
  }))
}

variable "random_suffix" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}

variable "public" {
  type    = bool
  default = false
}


variable "private_ssh_key" {
  type      = string
  sensitive = true
}

variable "bastion_host_ip" {
  type    = string
  default = ""
}

variable "allowed_plane_ips" {
  type    = list(string)
  default = []
}

variable "control_plane_endpoint_dns_name" {
  type    = string
  default = null
}

variable "lb_target_group_id" {
  type = string
}

variable "lb_target_assoc" {
  type = list(object({
    lb_target_group_id = string
    port               = number
  }))
  default = []
}

variable "sm_token_id" {
  type = string
}

variable "instance_policies" {
  type    = list(string)
  default = []
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the instance in."
  type        = string
}

variable "security_group_id" {
  description = "The ID of the security group to associate with the instance."
  type        = string
}

variable "allowed_ssh_ip" {
  description = "IP address (CIDR notation) that is allowed to SSH to the instance."
  type        = string
  default     = "0.0.0.0/0" # Default to allow from anywhere, but you should definitely restrict this.
}

variable "startup_script" {
  description = "Shell script to execute upon instance startup."
  type        = string
  default     = "" # Default to no script
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    "ManagedBy" = "Terraform"
  }
}

