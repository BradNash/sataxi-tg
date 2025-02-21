locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-mq-secrets"
}

dependency "rabbit_mq" {
  config_path = "${dirname(get_original_terragrunt_dir())}/rabbit-mq"
}

inputs = {
  environment   = "${local.env_vars.locals.environment}"
  mq_username   = dependency.rabbit_mq.outputs.mq_username
  mq_password   = dependency.rabbit_mq.outputs.mq_password
  ampq_endpoint = dependency.rabbit_mq.outputs.amqp_endpoint
  tags = {
    "map-migrated" = "d-server-03carvz5colf02"
  }
}
