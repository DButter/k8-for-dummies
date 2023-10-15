# Fetch the desired AMI based on the provided criteria.
data "aws_ami" "selected" {
  most_recent = true

  filter {
    name   = "name"
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
  vpc_id      = var.vpc_id
  tags = merge(var.tags, {
    Name = "initial-master-sg-${var.random_suffix}"
  })
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
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.this.id
  source_security_group_id = var.security_group_id
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
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = var.security_group_id
  security_group_id = aws_security_group.this.id
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
  policy_arn = var.allow_secretmanager
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.selected.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id, aws_security_group.this.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  key_name        = var.key_name
  user_data       = templatefile("${path.module}/init.sh.tpl", {
    control_plane_endpoint = var.control_plane_endpoint_dns_name
    secret_manager_id      = var.sm_token_id
  }) # + var.startup_script

  tags = merge(var.tags, {
    Name = "initial-master-${var.random_suffix}"
  })

  associate_public_ip_address = true

}

