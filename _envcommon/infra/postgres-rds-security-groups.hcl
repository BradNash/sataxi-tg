locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-rds-security-groups"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

dependency "fargate_task_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/fargate-task-sg"
}

inputs = {
  environment                = "${local.env_vars.locals.environment}"
  fargate_vpc_id             = dependency.data.outputs.vpc_id
  fargate_vpc_cidr_block     = dependency.data.outputs.vpc_cidr_block
  fargate_task_id            = dependency.fargate_task_sg.outputs.id
  security_group_name        = "sataxi-postgres-sg"
  security_group_description = "Postgres security group"
}

# TODO: Figure out if temporary can be removed from underlying module
# TODO: Maybe only use cloudposse module instead of custom module
