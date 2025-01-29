provider "aws" {
  region  = "ap-northeast-1"
  profile = var.aws_profile
}

provider "aws" {
  alias   = "secondary_b"
  region  = "us-east-1"
  profile = var.aws_profile
}

provider "aws" {
  alias   = "secondary_c"
  region  = "us-west-2"
  profile = var.aws_profile
}

terraform {
  backend "local" {
    path = ".cache/terraform.tfstate"
  }
}


# --------------------------------------------------------------------------------

# ■ variables.tf

# --------------------------------------------------------------------------------
variable "aws_profile" {
  type    = string
}

variable "primary_vpc_name" {
  type    = string
  default = "multi-region-vpc-primary"
}

variable "secondary_vpc_name_b" {
  type    = string
  default = "multi-region-vpc-secondary-b"
}

variable "secondary_vpc_name_c" {
  type    = string
  default = "multi-region-vpc-secondary-c"
}

variable "primary_vpc_cidr_block" {
  type    = string
  default = "172.19.0.0/20"
}

variable "secondary_vpc_cidr_block_b" {
  type    = string
  default = "172.19.16.0/20"
}

variable "secondary_vpc_cidr_block_c" {
  type    = string
  default = "172.19.32.0/20"
}

# それぞれのリージョンに合わせた AZ リストを指定
variable "primary_azs" {
  type    = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

variable "secondary_azs_b" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1c", "us-east-1d"]
}

variable "secondary_azs_c" {
  type    = list(string)
  default = ["us-west-2a", "us-west-2c", "us-west-2d"]
}
