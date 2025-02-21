include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/infra/postgres-rds.hcl"
  expose = true
}

terraform {
  source = "${include.envcommon.locals.base_source_url}?ref=master"
}

inputs = {
  snapshot_identifier = "sataxi-qa-202208031835"
}
