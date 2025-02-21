include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::codecommit::eu-west-1://SaTaxiPreProd@sataxi-tf-modules//sataxi-asterisk-ingress?ref=master"
}

dependency "fargate_private_alb_listener" {
  config_path = "../fargate-private-alb-listener"
}

dependency "data" {
  config_path = "../data"
}

inputs = {
  main_vpc_id           = dependency.data.outputs.vpc_id
  environment           = "dev"
  asterisk_instance_id  = "i-0c6e4811b395c08b8"
  service_parent_domain = "dev.sataxi-cloud.co.za"
  alb_listener_arn      = dependency.fargate_private_alb_listener.outputs.vanguard_lb_listner_arn
}
