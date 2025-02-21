locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-rds"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

dependency "postgres_rds_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/postgres-rds-sg"
}

inputs = {
  environment             = "${local.env_vars.locals.environment}"
  subnet_ids              = dependency.data.outputs.private_subnet_ids
  hosted_zone_id          = dependency.data.outputs.private_zone_id
  vpc_security_group_ids  = [dependency.postgres_rds_sg.outputs.id]
  rds_identifier          = "sataxi"
  rds_db_name             = "Vanguard"
  username                = "postgres_admin"
  rds_port                = 5432
  rds_engine_type         = "postgres"
  rds_engine_version      = "13.7"
  rds_family              = "postgres13"
  major_engine_version    = "13"
  monitoring_role_name    = "vanguard-rds-monitoring"
  dns_name                = "main-db.${local.env_vars.locals.environment}.sataxi-cloud.co.za"
  publicly_accessible     = false
  instance_class          = "db.t3.small"
  allocated_storage       = 20
  apply_immediately       = false
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  monitoring_interval     = "30"
  create_monitoring_role  = true
  deletion_protection     = false
  backup_retention_period = 14
  storage_encrypted       = true
  db_subnet_group_name    = "sataxi-db-subnet-group"
  tags = {
    "map-dba" = "d-server-03carvz5colf02"
  }
}
