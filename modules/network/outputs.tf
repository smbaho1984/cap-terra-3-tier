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
# output "public_subnet-1" {
#     value = aws_subnet.public_subnet_1
# }

# output "public_subnet-2" {
#     value = aws_subnet.public_subnet_2
# }

# output "public_subnet-3" {
#     value = aws_subnet.public_subnet_3
# }

# output "private_subnet-1" {
#     value = aws_subnet.private_subnet_1
# }

# output "private_subnet-2" {
#     value = aws_subnet.private_subnet_2
# }

# output "private_subnet-3" {
#     value = aws_subnet.private_subnet_3
# }