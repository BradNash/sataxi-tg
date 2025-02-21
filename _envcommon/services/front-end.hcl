inputs = {
  service_name       = "front-end"
  container_port     = 80
  health_check_path  = "/"
  ssm_paramater_tier = "Advanced"
}
