include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/infra/fargate-task-sg.hcl"
  expose = true
}

terraform {
  source = include.envcommon.locals.base_source_url
}
