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
  certificate_arn = "arn:aws:acm:af-south-1:665316528893:certificate/84dedc13-bbc7-498c-94c7-202d0b27942e"
}
