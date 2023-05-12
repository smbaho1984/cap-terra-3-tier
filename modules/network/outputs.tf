output "vpc_id" {
    value = aws_vpc.my_vpc.id
}

data "aws_subnet" "public_subnet_1" {
  filter {
    name = "tag:Name"
    values = ["dev-public-subnet-1"]
  }
}
output "public_subnet_id" {
    value = data.aws_subnet.public_subnet_1.id
  
}

data "aws_subnet" "public_subnet_2" {
  filter {
    name = "tag:Name"
    values = ["dev-public-subnet-2"]
  }
}
output "public_subnet_id_2" {
    value = data.aws_subnet.public_subnet_2.id
}

