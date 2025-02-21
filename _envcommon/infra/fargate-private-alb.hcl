locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-fargate-alb"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

dependency "fargate_private_alb_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/fargate-private-alb-sg"
}

inputs = {
  aws_account_id                    = "${local.account_vars.locals.aws_account_id}"
  environment                       = "${local.env_vars.locals.environment}"
  lb_name                           = "vanguard-sataxi"
  lb_type                           = "application"
  lb_address_type                   = "ipv4"
  lb_subnets                        = dependency.data.outputs.private_subnet_ids
  iam_fullaccess_policy_name        = "vangaurd-alb-access-logs-full-access"
  iam_fullaccess_policy_path        = "/"
  iam_fullaccess_policy_description = "S3 Full access policy for config file bucket"
  vanguard_fargate_alb_sg_id        = dependency.fargate_private_alb_sg.outputs.id
  bucket_acl                        = "private"
  tags = {
    "map-migrated" = "d-server-03carvz5colf02"
  }
}
