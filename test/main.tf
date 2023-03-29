provider "aws" {
  
}

module "vpc" {
    source = "../modules/network"
    tags = "test"
    vpc_cidr_block = "10.0.0.0/24"
    availability_zone = "us-west-2"  
}