include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/infra/fargate-private-alb-listener.hcl"
  expose = true
}

terraform {
  source = include.envcommon.locals.base_source_url
}

inputs = {
  certificate_arn = "arn:aws:acm:af-south-1:665316528893:certificate/aaf19384-263a-4313-8f01-e36f569b61d7" # TODO: Possible to get from data?
}
