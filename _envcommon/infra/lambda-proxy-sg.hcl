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
  description      = "Allow access to the lambda proxy"
  attributes       = ["lambda-proxy-sg-${local.env_vars.locals.environment}"]
  allow_all_egress = true

  rules = [
    {
      description              = "Allow access to the lambda proxy"
      protocol                 = "-1"
      type                     = "ingress"
      from_port                = 0
      to_port                  = 0
      cidr_blocks              = ["0.0.0.0/0"]
      ipv6_cidr_blocks         = ["::/0"]
      prefix_list_ids          = null
      source_security_group_id = null
      self                     = null
    }
  ]
}
