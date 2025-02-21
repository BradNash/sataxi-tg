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
  certificate_arn = "arn:aws:acm:af-south-1:743730760644:certificate/8239c7bb-1c11-4c54-b3bd-c29ee544472e" # TODO: Possible to get from data?
}
