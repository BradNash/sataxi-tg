locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "tfr:///cloudposse/security-group/aws?version=0.4.3"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

inputs = {
  vpc_id           = dependency.data.outputs.vpc_id
  description      = "Controls access for private ALB"
  attributes       = ["vanguard-fargate-private-alb-sg-${local.env_vars.locals.environment}"]
  allow_all_egress = true

  rules = [
    {
      description      = "Allow traffic on port 80 from inside VPC and from on Prem via VPN"
      protocol         = "tcp"
      type             = "ingress"
      from_port        = 80
      to_port          = 80
      cidr_blocks      = [dependency.data.outputs.vpc_cidr_block, "10.0.0.0/8", "172.26.0.0/15", "192.168.0.0/16"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "Allow traffic on port 443 from inside VPC and from on Prem via VPN"
      protocol         = "tcp"
      type             = "ingress"
      from_port        = 443
      to_port          = 443
      cidr_blocks      = [dependency.data.outputs.vpc_cidr_block, "10.0.0.0/8", "172.26.0.0/15", "192.168.0.0/16"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "Allow traffic on port 8089 (Asterisk) from inside VPC and from on Prem via VPN"
      protocol         = "tcp"
      type             = "ingress"
      from_port        = 8089
      to_port          = 8089
      cidr_blocks      = [dependency.data.outputs.vpc_cidr_block, "10.0.0.0/8", "172.26.0.0/15", "192.168.0.0/16"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    },
    {
      description      = "Allow traffic on port 5060 (Asterisk) from inside VPC and from on Prem via VPN"
      protocol         = "tcp"
      type             = "ingress"
      from_port        = 5060
      to_port          = 5060
      cidr_blocks      = [dependency.data.outputs.vpc_cidr_block, "10.0.0.0/8", "172.26.0.0/15", "192.168.0.0/16"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]
}
