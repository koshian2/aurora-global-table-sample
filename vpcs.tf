# ─────────────────────────────────────────────────────────────
# VPC モジュール呼び出し：Primary リージョン用
# ─────────────────────────────────────────────────────────────
module "vpc_primary" {
  source = "./modules/vpc"

  vpc_name           = var.primary_vpc_name
  vpc_cidr_block     = var.primary_vpc_cidr_block
  availability_zones = var.primary_azs
}

# ─────────────────────────────────────────────────────────────
# VPC モジュール呼び出し：Secondary リージョン用
# ─────────────────────────────────────────────────────────────
module "vpc_secondary_b" {
  source = "./modules/vpc"

  providers = {
    aws = aws.secondary_b
  }

  vpc_name           = var.secondary_vpc_name_b
  vpc_cidr_block     = var.secondary_vpc_cidr_block_b
  availability_zones = var.secondary_azs_b
}

module "vpc_secondary_c" {
  source = "./modules/vpc"

  providers = {
    aws = aws.secondary_c
  }

  vpc_name           = var.secondary_vpc_name_c
  vpc_cidr_block     = var.secondary_vpc_cidr_block_c
  availability_zones = var.secondary_azs_c
}