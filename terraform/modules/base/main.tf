

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "main-vpc-${var.random_suffix}"
  })
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidr_blocks)

  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = element(sort(data.aws_availability_zones.available.names), count.index)
  vpc_id            = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "subnet-${count.index}-${var.random_suffix}"
  })
}

resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidr_blocks)

  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = element(sort(data.aws_availability_zones.available.names), count.index)
  vpc_id            = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "subnet-${count.index}-${var.random_suffix}"
  })
}

#resource "aws_lb" "k8s_lb" {
#  internal                   = true
#  load_balancer_type         = "application"
#  enable_deletion_protection = false
#
#  enable_cross_zone_load_balancing = true
#  security_groups                  = [aws_security_group.lb.id]
#
#  subnets = aws_subnet.public_subnet.*.id
#  tags = merge(var.tags, {
#    Name = "lb-${var.random_suffix}"
#  })
#}

resource "aws_lb" "k8s_lb" {
  internal                   = true
  load_balancer_type         = "network"
  enable_deletion_protection = false

  enable_cross_zone_load_balancing = true
  security_groups                  = [aws_security_group.lb.id]

  subnets = aws_subnet.public_subnet.*.id
  tags = merge(var.tags, {
    Name = "lb-${var.random_suffix}"
  })
}

resource "aws_security_group" "lb" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "lb-sg-${var.random_suffix}"
  })
}

resource "aws_security_group_rule" "allow_lb_in" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_lb_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

#resource "aws_lb_target_group" "k8s_tg" {
#  port     = 6443
#  protocol = "HTTPS"
#  vpc_id   = aws_vpc.main.id
#
#  health_check {
#    protocol            = "HTTPS"
#    port                = "6443"
#    path                = "/readyz"
#    interval            = 30
#    timeout             = 10
#    healthy_threshold   = 3
#    unhealthy_threshold = 3
#  }
#  tags = var.tags
#}

resource "aws_lb_target_group" "k8s_tg" {
  port               = 6443
  protocol           = "TCP"
  vpc_id             = aws_vpc.main.id
  preserve_client_ip = false

  health_check {
    protocol            = "TCP"
    port                = "6443"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = var.tags
}

resource "tls_private_key" "ca_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca_key.private_key_pem

  subject {
    common_name  = "CA"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 87600
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing"
  ]
}

resource "tls_private_key" "lb_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "tls_cert_request" "this" {
  private_key_pem = tls_private_key.lb_key.private_key_pem
  dns_names = ["*.${var.dns_zone_name}"
  ]
}

resource "tls_locally_signed_cert" "lb_cert" {
  cert_request_pem   = tls_cert_request.this.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 87600
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "lb_cert" {
  private_key      = tls_private_key.lb_key.private_key_pem
  certificate_body = tls_locally_signed_cert.lb_cert.cert_pem
}

#resource "aws_lb_listener" "k8s_listener" {
#  load_balancer_arn = aws_lb.k8s_lb.arn
#  port              = "6443"
#  protocol          = "HTTPS"
#  certificate_arn   = aws_acm_certificate.lb_cert.arn
#
#  default_action {
#    type             = "forward"
#    target_group_arn = aws_lb_target_group.k8s_tg.arn
#  }
#  tags = var.tags
#}

resource "aws_lb_listener" "k8s_listener" {
  load_balancer_arn = aws_lb.k8s_lb.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_tg.arn
  }
  tags = var.tags
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "main-igw-${var.random_suffix}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "public-route-table-${var.random_suffix}"
  })
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = merge(var.tags, {
    Name = "NAT-Gateway-${var.random_suffix}"
  })
}


resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = merge(var.tags, {
    Name = "private-route-table-${var.random_suffix}"
  })
}

resource "aws_route_table_association" "private_route_table_assoc" {
  count          = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route53_zone" "private_zone" {
  name = var.dns_zone_name
  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = merge(var.tags, {
    Name = "private-dns-zone-${var.random_suffix}"
  })
}

data "aws_availability_zones" "available" {}

resource "aws_security_group" "empty_sg" {
  description = "An empty security group"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "general-sg-${var.random_suffix}"
  })
}

resource "aws_security_group_rule" "allow_self_in" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.empty_sg.id
  self              = true
}

resource "aws_security_group_rule" "allow_all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.empty_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_route53_record" "plane_record" {
  zone_id = aws_route53_zone.private_zone.id
  name    = var.plane_record_name
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.k8s_lb.dns_name]
}