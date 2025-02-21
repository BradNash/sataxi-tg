inputs = {
  service_name      = "keycloak"
  container_port    = 8080
  cpu               = 512
  memory            = 1024
  health_check_path = "/auth/realms/master"
}