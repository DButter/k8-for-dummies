# variable.tf

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "random_suffix" {
  type        = string
}

variable "subnet_cidr_blocks" {
  description = "List of CIDR blocks for the subnets"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "dns_zone_name" {
  description = "Name for the private DNS zone"
  type        = string
  default     = "private.local"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    "ManagedBy" = "Terraform"
  }
}

