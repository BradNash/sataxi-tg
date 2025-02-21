inputs = {
  service_name      = "otel-collector"
  container_port    = 4318
  health_check_port = 13133
  health_check_path = "/"
}
