locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-ssm-parameter-secrets"
}

inputs = {
  paramaters = [
    {
      name        = "/${local.env_vars.locals.environment}/secret/hive_db_username"
      description = "DB Username for ${local.env_vars.locals.environment} Hive DB"
    },
    {
      name        = "/${local.env_vars.locals.environment}/secret/hive_db_password"
      description = "DB Password for ${local.env_vars.locals.environment} Hive DB"
    },
    {
      name        = "/${local.env_vars.locals.environment}/secret/keycloak_username"
      description = "Username for ${local.env_vars.locals.environment} Keycloak"
      value       = "keycloak_admin"
    },
    {
      name        = "/${local.env_vars.locals.environment}/secret/keycloak_password"
      description = "Password ${local.env_vars.locals.environment} Keycloak"
    }
  ]
}
