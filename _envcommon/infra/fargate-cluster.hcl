locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-fargate-cluster" # TODO: Possible use cloudposse module instead
}

inputs = {
  cluster_name = "vanguard-fargate-cluster-${local.env_vars.locals.environment}"
  tags = {
    environment    = "${local.env_vars.locals.environment}"
    "map-migrated" = "d-server-03carvz5colf02"
  }
}
