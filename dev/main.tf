provider "aws" {
  
}

module "vpc" {
    source = "../modules/network"
    tags = "dev"
    vpc_cidr_block = "10.0.0.0/24"
    availability_zone = "us-west-2"  
}


module "ec2" {
  source = "../modules/compute"
  vpc_id = module.vpc.vpc_id
  subnet_ids = [module.vpc.public_subnet_1.id, module.vpc.public_subnet_2.id]
  tags = "app"
  ami_id = "ami-0efa651876de2a5ce"
  max_size = 3
  min_size = 2
  vpc_cidr_block = "10.0.0.0/24"
  desired_capacity = 2
  instance_type = "t2.micro"
}