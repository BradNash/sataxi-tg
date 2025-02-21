locals {
  env_vars        = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars    = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  base_source_url = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//vanguard-mq"
}

dependency "data" {
  config_path = "${dirname(get_original_terragrunt_dir())}/data"
}

dependency "rabbit_mq_sg" {
  config_path = "${dirname(get_original_terragrunt_dir())}/rabbit-mq-sg"
}

inputs = {
  environment             = "${local.env_vars.locals.environment}"
  mq_name                 = "rabbit-mq"
  vpc_id                  = dependency.data.outputs.vpc_id
  subnet_ids              = [dependency.data.outputs.private_subnet_ids[0]]
  security_groups_ids     = [dependency.rabbit_mq_sg.outputs.id]
  host_instance_type      = "mq.t3.micro"
  engine_type             = "RabbitMQ"
  engine_version          = "3.9.16"
  deployment_mode         = "SINGLE_INSTANCE"
  maintenance_day_of_week = "SUNDAY"
  maintenance_time_of_day = "03:00"
  maintenance_time_zone   = "UTC"
  mq_username             = "admin"
  tags = {
    "map-migrated" = "d-server-03carvz5colf02"
  }
}
