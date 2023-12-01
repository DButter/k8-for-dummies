# Fetch the desired AMI based on the provided criteria.
data "aws_ami" "selected" {
  most_recent = true

  filter {
    name = "name"
    # no kube packages for amazon linux 2023 yet
    # values = ["al2023-ami-2023*"]
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["amazon"]
}

resource "aws_security_group" "this" {
  vpc_id = var.vpc_id
  tags   = var.tags
}

resource "aws_security_group_rule" "allow_all_from_sg_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.this.id
  self              = true
}

resource "aws_security_group_rule" "allow_all_from_sg_base_sg" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.security_group_id
}

resource "aws_security_group_rule" "allow_plane_from_ips" {
  count             = length(var.allowed_plane_ips) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = var.allowed_plane_ips
  security_group_id = aws_security_group.this.id
}


resource "aws_security_group_rule" "allow_ssh_ip" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_ssh_ip]
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "allow_ssh_base_sg" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.security_group_id
  security_group_id        = aws_security_group.this.id
}

resource "aws_iam_role" "ec2_role" {

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_read_secret_attach" {
  for_each   = toset(var.instance_policies)
  policy_arn = each.key
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  role = aws_iam_role.ec2_role.name
}

locals {
  templated_files_content = [for config in var.template_configs : templatefile("${path.module}/${config.filename}", config.template_vars)]

  # Join all templated content into a single string, maintaining order
  merged_content = join("\n", local.templated_files_content)
}

resource "aws_instance" "public" {
  count                  = var.public ? 1 : 0
  ami                    = data.aws_ami.selected.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id, aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  key_name = var.ssh_key_name
  #user_data       = templatefile("${path.module}/init.sh.tpl", {
  #  control_plane_endpoint = var.control_plane_endpoint_dns_name
  #  secret_manager_id      = var.sm_token_id
  #}) # + var.startup_script

  tags = var.tags

  associate_public_ip_address = var.public

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = var.private_ssh_key

    host = self.public_ip
  }
  provisioner "file" {
    content     = local.merged_content
    destination = "/tmp/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /tmp/init.sh",
      "sudo /tmp/init.sh",
    ]
  }
}

resource "aws_instance" "private" {
  count                  = var.public ? 0 : 1
  ami                    = data.aws_ami.selected.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id, aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  key_name = var.ssh_key_name
  #user_data       = templatefile("${path.module}/init.sh.tpl", {
  #  control_plane_endpoint = var.control_plane_endpoint_dns_name
  #  secret_manager_id      = var.sm_token_id
  #}) # + var.startup_script

  tags = var.tags

}

resource "null_resource" "instance_setup" {
  depends_on = [aws_lb_target_group_attachment.k8s_tg_attachment, aws_instance.private]
  count      = var.public ? 0 : 1
  # Triggers to ensure this resource is recreated if the instance or attachment changes
  triggers = {
    instance_id = aws_instance.private[0].id
  }

  connection {
    type         = "ssh"
    user         = "ec2-user"
    private_key  = var.private_ssh_key
    host         = aws_instance.private[0].private_ip
    bastion_host = var.bastion_host_ip
  }

  provisioner "file" {
    content     = local.merged_content
    destination = "/tmp/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /tmp/init.sh",
      "sudo /tmp/init.sh",
    ]
  }
}


resource "aws_lb_target_group_attachment" "k8s_tg_attachment" {
  for_each         = { for assoc in var.lb_target_assoc : assoc.port => assoc }
  target_group_arn = each.value.lb_target_group_id
  target_id        = var.public ? aws_instance.public[0].id : aws_instance.private[0].id
  port             = each.value.port
}


