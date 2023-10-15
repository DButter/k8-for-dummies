resource "random_id" "tag_suffix" {
  byte_length = 4
}

locals {
  dns_zone_name = "k8.local"
}

module "base" {
  source           = "../modules/base"
  vpc_cidr_block   = "10.0.0.0/16"
  dns_zone_name    = local.dns_zone_name
  random_suffix = random_id.tag_suffix.hex
  tags = {
    "ManagedBy" = "David"
    "Environment" = "Dev"
  }
}

data "local_file" "public_key" {
  filename = "./id_ed25519.pub"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = data.local_file.public_key.content
}

data "local_file" "kubeadm_token" {
  filename   = "${path.module}/kubeadm_token.txt"
}

resource "aws_secretsmanager_secret" "kubeadm_token" {
  name = random_id.tag_suffix.hex
}

resource "aws_secretsmanager_secret_version" "kubeadm_token" {
  secret_id     = aws_secretsmanager_secret.kubeadm_token.id
  secret_string = data.local_file.kubeadm_token.content
}

resource "aws_iam_policy" "read_secret" {
  name        = "ReadKubeadmTokenSecret"
  description = "Allows reading the Kubeadm Token from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "secretsmanager:GetSecretValue",
        Effect = "Allow",
        Resource = aws_secretsmanager_secret.kubeadm_token.arn
      }
    ]
  })
}


module "initial_master" {
  source           = "../modules/initial_master"
  vpc_id = module.base.vpc_id
  random_suffix = random_id.tag_suffix.hex
  key_name = aws_key_pair.deployer.key_name
  control_plane_endpoint_dns_name = "plane.${local.dns_zone_name}"
  sm_token_id = aws_secretsmanager_secret.kubeadm_token.arn
  subnet_id = module.base.subnet_ids[0]
  security_group_id = module.base.base_security_group_id
  allow_secretmanager = aws_iam_policy.read_secret.arn
  allowed_ssh_ip = "84.115.209.147/32"
  tags = {
    "ManagedBy" = "David"
    "Environment" = "Dev"
  }
}
