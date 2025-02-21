data "terraform_remote_state" "this" {
  backend = "s3"
  config = {
    bucket  = "sataxi-shared-terraform-bucket"
    key     = "./VPCVanguardProd//terraform.tfstate"
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
  value = "172.28.32.0/21" # TODO: Check if this is in the state file somewhere?
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
  value = "Z06999132O93RN8X3L6EC" # TODO: Readd once migration is done: data.terraform_remote_state.this.outputs.private_zone_id
}

output "private_route_table_ids" {
  value = ["rtb-02c0df3e91ac6e83e", "rtb-058cbc8388b6f6681"]
}

output "azs" {
  value = ["af-south-1a", "af-south-1b"] # TODO: Check if used?
}
