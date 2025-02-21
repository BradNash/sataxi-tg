include "root" {
  path = find_in_parent_folders()
}

include "envcommon_services_common" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/services/_common.hcl"
  expose = true
}

include "envcommon_service" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/services/front-end.hcl"
  expose = true
}

terraform {
  source = "${include.envcommon_services_common.locals.base_source_url}?ref=master"
}

inputs = {
  service_subdomain = "vanguard"
}
