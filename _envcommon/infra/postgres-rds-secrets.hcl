locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-rds-secrets"
}

dependency "postgres_rds" {
  config_path = "${dirname(get_original_terragrunt_dir())}/postgres-rds"
}

inputs = {
  environment          = "${local.env_vars.locals.environment}"
  secret_name          = "rds-postgres-credentials"
  cluster_identifier   = "sataxi-${local.env_vars.locals.environment}" # TODO: CHeck if prod needs -prod?
  rds_username         = dependency.postgres_rds.outputs.db_instance_username
  rds_master_password  = dependency.postgres_rds.outputs.db_instance_password
  rds_port             = dependency.postgres_rds.outputs.db_instance_port
  rds_db_name          = dependency.postgres_rds.outputs.db_instance_name
  rds_engine_type      = dependency.postgres_rds.outputs.db_instance_type
  rds_instance_address = dependency.postgres_rds.outputs.db_instance_address
  tags = {
    "map-migrated" = "d-server-03carvz5colf02"
  }
}
