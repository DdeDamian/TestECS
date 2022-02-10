# -------------------------------------------------------------
# AWS VPC and subnets
# -------------------------------------------------------------

module "vpc" {
  # We will be using community modules to keep them up-to-date
  source = "terraform-aws-modules/vpc/aws"

  name            = local.vpc_name[terraform.workspace]
  cidr            = local.vpc_cidr[terraform.workspace]
  azs             = local.azs[terraform.workspace]
  public_subnets  = local.public_subnets_cidrs[terraform.workspace]
  private_subnets = local.private_subnets_cidrs[terraform.workspace]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "${terraform.workspace}"
  }
}
