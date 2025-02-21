locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  base_source_url = "tfr:///cloudposse/sns-topic/aws?version=0.20.1"
}

inputs = {
  name = "vanguard-alarms-notification-${local.env_vars.locals.environment}"
  tags = {
    CreatedBy = "Terraform Framework"
    Environment = local.env_vars.locals.environment,
    Owner = "Terraform OPS"
  }
}