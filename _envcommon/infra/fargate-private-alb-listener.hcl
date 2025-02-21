locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-fargate-lb-listener"
}

dependency "fargate_private_alb" {
  config_path = "${dirname(get_original_terragrunt_dir())}/fargate-private-alb"
}


inputs = {
  name        = "vanguard-lb-listner"
  environment = "${local.env_vars.locals.environment}"
  vanguard_fargate_alb_arn = dependency.fargate_private_alb.outputs.vanguard_fargate_alb_arn
}
