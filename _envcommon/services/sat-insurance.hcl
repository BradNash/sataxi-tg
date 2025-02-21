inputs = {
  service_name                = "sat-insurance"
  create_service_internal_dns = true
  container_port              = 8080
  health_check_path           = "/health_check"
  create_lambda_proxy         = true
}
