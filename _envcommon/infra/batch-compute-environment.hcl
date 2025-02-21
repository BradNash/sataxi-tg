locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-batch-compute-environment"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

dependency "batch_compute_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/batch-compute-sg"
}

inputs = {
  compute_environment_name = "sataxi"
  environment              = local.env_vars.locals.environment
  security_group_ids       = [dependency.batch_compute_sg.outputs.id]
  subnet_ids               = dependency.data.outputs.private_subnet_ids

  tags = {
    "map-migrated" = "d-server-03carvz5colf02"
  }
}
