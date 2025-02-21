locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "tfr:///cloudposse/ssm-parameter-store/aws?version=0.9.1"
}

dependency "postgres_rds" {
  config_path = "${dirname(get_original_terragrunt_dir())}/postgres-rds"
}

dependency "sqlserver_rds" {
  config_path = "${dirname(get_original_terragrunt_dir())}/sqlserver-rds"
}

inputs = {
  parameter_write = [
    {
      name        = "/${local.env_vars.locals.environment}/databases/identity/connection-string"
      value       = "User ID=${dependency.postgres_rds.outputs.db_instance_username};Password=${dependency.postgres_rds.outputs.db_instance_password};Host=${dependency.postgres_rds.outputs.db_instance_address};Port=${dependency.postgres_rds.outputs.db_instance_port};Database=vanguard-identity-v4;Pooling=true;"
      type        = "SecureString"
      overwrite   = "true"
      description = "ASPNETCORE PostgreSQL Connection String for Identity Database"
    },
    {
      name        = "/${local.env_vars.locals.environment}/databases/security/connection-string"
      value       = "User ID=${dependency.postgres_rds.outputs.db_instance_username};Password=${dependency.postgres_rds.outputs.db_instance_password};Host=${dependency.postgres_rds.outputs.db_instance_address};Port=${dependency.postgres_rds.outputs.db_instance_port};Database=vanguard-security;Pooling=true;"
      type        = "SecureString"
      overwrite   = "true"
      description = "ASPNETCORE PostgreSQL Connection String for Security Database"
    },
    {
      name        = "/${local.env_vars.locals.environment}/databases/sat-insurance/connection-string"
      value       = "User ID=${dependency.postgres_rds.outputs.db_instance_username};Password=${dependency.postgres_rds.outputs.db_instance_password};Host=${dependency.postgres_rds.outputs.db_instance_address};Port=${dependency.postgres_rds.outputs.db_instance_port};Database=insurance;Pooling=true;"
      type        = "SecureString"
      overwrite   = "true"
      description = "ASPNETCORE SQLServer Connection String for insurance Database"
    },
  ]
}
