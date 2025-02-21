locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  base_source_url = "tfr:///cloudposse/security-group/aws?version=1.0.1"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

inputs = {
  vpc_id           = dependency.data.outputs.vpc_id
  description      = "Allows access to Rabbit MQ"
  attributes       = ["rabbit-mq-sg-${local.env_vars.locals.environment}"]
  allow_all_egress = true

  rules = [
    {
      type        = "ingress"
      from_port   = 5671
      to_port     = 5671
      protocol    = "tcp"
      cidr_blocks = [dependency.data.outputs.vpc_cidr_block]
      self        = null
      description = "Allow traffic on port 5167 from inside VPC"
    },
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
      self        = null
      description = "Allow HTTPS traffic from on Prem via VPN"
    },
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["172.26.0.0/15"]
      self        = null
      description = "Allow HTTPS traffic from on Prem via VPN"
    },
    {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["192.168.0.0/16"]
      self        = null
      description = "Allow HTTPS traffic from on Prem via VPN"
    }
  ]
}
