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
  description      = "Controls access to batch jobs"
  attributes       = ["vanguard-batch-compute-${local.env_vars.locals.environment}"]
  allow_all_egress = true
  rules            = []
}
