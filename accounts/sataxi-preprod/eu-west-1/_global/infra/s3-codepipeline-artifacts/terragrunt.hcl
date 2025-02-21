include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///cloudposse/s3-bucket/aws?version=0.49.0"
}

inputs = {
  acl = "private"
  versioning_enabled = true
  name = "sataxi-codepipeline-artifacts"
}