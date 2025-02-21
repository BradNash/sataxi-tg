locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//service-discovery-namespace"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

inputs = {
  vpc_id = dependency.data.outputs.vpc_id
}
