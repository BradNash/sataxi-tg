inputs = {
  service_name                = "identity"
  create_service_internal_dns = true
  container_port              = 8080
  health_check_path           = "/health"
}
