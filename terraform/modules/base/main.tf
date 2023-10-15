

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "main-vpc-${var.random_suffix}"
  })
}

resource "aws_subnet" "subnet" {
  count = length(var.subnet_cidr_blocks)

  cidr_block        = var.subnet_cidr_blocks[count.index]
  availability_zone = element(sort(data.aws_availability_zones.available.names), count.index)
  vpc_id            = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "subnet-${count.index}-${var.random_suffix}"
  })
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
  count = length(var.subnet_cidr_blocks)

  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route53_zone" "private_zone" {
  name = var.dns_zone_name
  vpc  {
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

resource "aws_security_group_rule" "allow_all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.empty_sg.id
  cidr_blocks      = ["0.0.0.0/0"]
}