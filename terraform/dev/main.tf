resource "random_id" "tag_suffix" {
  byte_length = 4
}

locals {
  dns_zone_name  = "k8.local"
  plane_dns_name = "plane.${local.dns_zone_name}"
  tags = {
    "ManagedBy"   = "David"
    "Environment" = "Dev"
  }
  vpc_cidr_block             = "10.0.0.0/16"
  public_subnet_cidr_blocks  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidr_blocks = ["10.0.16.0/20", "10.0.32.0/20", "10.0.48.0/20"]
  pod_network_cidr           = "172.16.0.0/12"
  masters                    = ["master0"]
  nodes                      = ["node0", "node1", "node2"]
}

module "base" {
  source                     = "../modules/base"
  vpc_cidr_block             = local.vpc_cidr_block
  public_subnet_cidr_blocks  = local.public_subnet_cidr_blocks
  private_subnet_cidr_blocks = local.private_subnet_cidr_blocks
  dns_zone_name              = local.dns_zone_name
  plane_record_name          = local.plane_dns_name
  random_suffix              = random_id.tag_suffix.hex
  kubeadm_token              = data.local_file.kubeadm_token.content
  cert_key                   = data.local_file.certificateKey.content
  tags                       = local.tags
}

data "local_file" "public_key" {
  filename = "./id_ed25519.pub"
}


data "local_file" "kubeadm_token" {
  filename = "${path.module}/kubeadm_token.txt"
}

data "local_file" "certificateKey" {
  filename = "${path.module}/kubeadm_cert_key.txt"
}

module "jump_host" {
  source             = "../modules/ec2_instance"
  vpc_id             = module.base.vpc_id
  random_suffix      = random_id.tag_suffix.hex
  ssh_key_name       = module.base.aws_key_pair.key_name
  lb_target_group_id = module.base.lb_target_group_id
  sm_token_id        = module.base.aws_secretsmanager_secret_arn
  subnet_id          = module.base.public_subnet_ids[0]
  security_group_id  = module.base.base_security_group_id
  public             = true
  allowed_ssh_ip     = "84.115.209.122/32"
  private_ssh_key    = module.base.tls_private_key.private_key_pem
  template_configs = [
    {
      filename = "init.sh.tpl"
      template_vars = {
        public_key = replace(data.local_file.public_key.content, "\n", "")
      }
    }
  ]
  tags = merge(local.tags, {
    Name = "jump-host-${random_id.tag_suffix.hex}"
  })
}


module "initial_master" {
  source                          = "../modules/ec2_instance"
  vpc_id                          = module.base.vpc_id
  random_suffix                   = random_id.tag_suffix.hex
  ssh_key_name                    = module.base.aws_key_pair.key_name
  control_plane_endpoint_dns_name = module.base.lb_dns_name
  lb_target_group_id              = module.base.lb_target_group_id
  sm_token_id                     = module.base.aws_secretsmanager_secret_arn
  subnet_id                       = module.base.private_subnet_ids[0]
  allowed_plane_ips               = concat(local.public_subnet_cidr_blocks, local.private_subnet_cidr_blocks, [local.pod_network_cidr])
  security_group_id               = module.base.base_security_group_id
  instance_policies               = [module.base.aws_iam_policy_arn]
  allowed_ssh_ip                  = "84.115.209.122/32"
  private_ssh_key                 = module.base.tls_private_key.private_key_openssh
  instance_dns_settings = {
    zone_id   = module.base.private_dns_zone_id
    node_name = "initial-master.k8.local"
  }
  template_configs = [
    {
      filename = "init.sh.tpl"
      template_vars = {
        public_key = replace(data.local_file.public_key.content, "\n", "")
      }
    },
    {
      filename = "kubeadm.sh.tpl"
      template_vars = {
        secret_manager_id = module.base.aws_secretsmanager_secret_arn,
        node_name         = "initial-master.k8.local"
        pod_network_cidr  = local.pod_network_cidr
      }
    },
    #{
    #  filename = "flannel/installflannel.sh.tpl"
    #  template_vars = {
    #    pod_network_cidr = local.pod_network_cidr
    #  }
    #}
  ]
  bastion_host_ip = module.jump_host.instance_public_ip
  lb_target_assoc = [
    {
      lb_target_group_id = module.base.lb_target_group_id
      port               = 6443
    }
  ]
  tags = merge(local.tags, {
    Name = "initial-master-${random_id.tag_suffix.hex}"
  })
}

module "masters" {
  for_each                        = toset(local.masters)
  source                          = "../modules/ec2_instance"
  vpc_id                          = module.base.vpc_id
  random_suffix                   = random_id.tag_suffix.hex
  ssh_key_name                    = module.base.aws_key_pair.key_name
  control_plane_endpoint_dns_name = module.base.lb_dns_name
  lb_target_group_id              = module.base.lb_target_group_id
  sm_token_id                     = module.base.aws_secretsmanager_secret_arn
  subnet_id                       = module.base.private_subnet_ids[0]
  allowed_plane_ips               = concat(local.public_subnet_cidr_blocks, local.private_subnet_cidr_blocks)
  security_group_id               = module.base.base_security_group_id
  instance_policies               = [module.base.aws_iam_policy_arn]
  allowed_ssh_ip                  = "84.115.209.122/32"
  private_ssh_key                 = module.base.tls_private_key.private_key_openssh
  instance_dns_settings = {
    zone_id   = module.base.private_dns_zone_id
    node_name = "${each.key}.k8.local"
  }
  template_configs = [
    {
      filename = "init.sh.tpl"
      template_vars = {
        public_key = replace(data.local_file.public_key.content, "\n", "")
      }
    },
    {
      filename = "joinMaster.sh.tpl"
      template_vars = {
        secret_manager_id = module.base.aws_secretsmanager_secret_arn,
        node_name         = "${each.key}.k8.local"
      }
    }
  ]
  bastion_host_ip = module.jump_host.instance_public_ip
  lb_target_assoc = [
    {
      lb_target_group_id = module.base.lb_target_group_id
      port               = 6443
    }
  ]
  tags = merge(local.tags, {
    Name = "${each.key}-${random_id.tag_suffix.hex}"
  })
}

module "nodes" {
  for_each                        = toset(local.nodes)
  source                          = "../modules/ec2_instance"
  vpc_id                          = module.base.vpc_id
  random_suffix                   = random_id.tag_suffix.hex
  ssh_key_name                    = module.base.aws_key_pair.key_name
  control_plane_endpoint_dns_name = module.base.lb_dns_name
  lb_target_group_id              = module.base.lb_target_group_id
  sm_token_id                     = module.base.aws_secretsmanager_secret_arn
  subnet_id                       = module.base.private_subnet_ids[0]
  allowed_plane_ips               = concat(local.public_subnet_cidr_blocks, local.private_subnet_cidr_blocks)
  security_group_id               = module.base.base_security_group_id
  instance_policies               = [module.base.aws_iam_policy_arn]
  allowed_ssh_ip                  = "84.115.209.122/32"
  private_ssh_key                 = module.base.tls_private_key.private_key_openssh
  instance_dns_settings = {
    zone_id   = module.base.private_dns_zone_id
    node_name = "${each.key}.k8.local"
  }
  template_configs = [
    {
      filename = "init.sh.tpl"
      template_vars = {
        public_key = replace(data.local_file.public_key.content, "\n", "")
      }
    },
    {
      filename = "joinWorker.sh.tpl"
      template_vars = {
        secret_manager_id = module.base.aws_secretsmanager_secret_arn,
        node_name         = "${each.key}.k8.local"
      }
    }
  ]
  bastion_host_ip = module.jump_host.instance_public_ip
  tags = merge(local.tags, {
    Name = "${each.key}-${random_id.tag_suffix.hex}"
  })
}
