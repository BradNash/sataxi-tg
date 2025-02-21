data "terraform_remote_state" "this" {
  backend = "s3"
  config = {
    bucket  = "sataxi-shared-terraform-bucket"
    key     = "./VPCVanguardDev//terraform.tfstate"
    region  = "af-south-1"
    profile = "SaTaxiShared"
  }
}

# --------
# Outputs
# --------

output "vpc_id" {
  value = data.terraform_remote_state.this.outputs.vpc_id
}

output "vpc_cidr_block" {
  value = "172.28.16.0/21" # TODO: Check if this is in the state file somewhere?
}

output "private_subnet_ids" {
  value = [for r in data.terraform_remote_state.this.outputs.private_subnets : "${r.id}"]
}

output "public_subnet_ids" {
  value = [for r in data.terraform_remote_state.this.outputs.public_subnets : "${r.id}"]
}

output "isolated_subnet_ids" {
  value = [for r in data.terraform_remote_state.this.outputs.isolated_subnets : "${r.id}"]
}

output "private_zone_id" {
  value = "Z1046386IYR0PGYMM8NQ" # TODO: Readd once migration is done: data.terraform_remote_state.this.outputs.private_zone_id
}

output "private_route_table_ids" {
  value = ["rtb-03305ce08cc17ad94", "rtb-0d295c26b683e9bb3"]
}

output "azs" {
  value = ["af-south-1a", "af-south-1b"] # TODO: Check if used?
}
