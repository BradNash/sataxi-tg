locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "tfr:///cloudposse/route53-alias/aws?version=0.13.0"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

dependency "fargate_private_alb" {
  config_path = "${dirname(get_original_terragrunt_dir())}/fargate-private-alb"
}

inputs = {
  parent_zone_id  = dependency.data.outputs.private_zone_id
  target_dns_name = dependency.fargate_private_alb.outputs.vanguard_fargate_alb_dns_name
  target_zone_id  = dependency.fargate_private_alb.outputs.vanguard_fargate_alb_zone_id
}
