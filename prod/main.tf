provider "aws" {
  
}

module "network" {
    source = "../modules/network"
    tags = "prod"
    vpc_cidr_block = "10.0.0.0/25"
    availability_zone = "us-west-2"  
}