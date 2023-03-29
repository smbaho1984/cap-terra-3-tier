locals {
  vpc_cidr_block = var.vpc_cidr_block #"10.0.0.0/24"
  # splitting up the CIDR block into 3 equal subnets with a /27 subnet mask for public subnets
  public_subnet_cidr_blocks = [
    cidrsubnet(local.vpc_cidr_block, 3, 0),
    cidrsubnet(local.vpc_cidr_block, 3, 1),
    cidrsubnet(local.vpc_cidr_block, 3, 2),
  ]
  # splitting up the CIDR block into 3 equal subnets with a /27 subnet mask for private subnets
  private_subnet_cidr_blocks = [
    cidrsubnet(local.vpc_cidr_block, 3, 3),
    cidrsubnet(local.vpc_cidr_block, 3, 4),
    cidrsubnet(local.vpc_cidr_block, 3, 5),
  ]
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.tags}-vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = local.public_subnet_cidr_blocks[0]
  availability_zone = "${var.availability_zone}a"
  tags = {
    Name = "${var.tags}-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = local.public_subnet_cidr_blocks[1]
  availability_zone = "${var.availability_zone}b"
  tags = {
    Name = "${var.tags}-public-subnet-2"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = local.public_subnet_cidr_blocks[2]
  availability_zone = "${var.availability_zone}c"
  tags = {
    Name = "${var.tags}-public-subnet-3"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = local.private_subnet_cidr_blocks[0]
  availability_zone = "${var.availability_zone}a"
  tags = {
    Name = "${var.tags}-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = local.private_subnet_cidr_blocks[1]
  availability_zone = "${var.availability_zone}b"
  tags = {
    Name = "${var.tags}-private-subnet-2"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = local.private_subnet_cidr_blocks[2]
  availability_zone = "${var.availability_zone}c"
  tags = {
    Name = "${var.tags}-private-subnet-3"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.tags}-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.tags}-publicRouteTable"
  }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_3_association" {
  subnet_id      = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.tags}-privateRouteTable"
  }
}

resource "aws_route" "internet_gateway_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# Create a NAT Gateway and an Elastic IP
resource "aws_eip" "my_eip" {
  vpc = true
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = "${var.tags}-NTG"
  }
}

resource "aws_route" "nat_gateway_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway.id

}
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_3_association" {
  subnet_id      = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private_route_table.id
}

# Create the Transit Gateway
resource "aws_ec2_transit_gateway" "my_transit_gateway" {
  description = "Transit gateway for ${var.tags}"
  tags = {
    "Name" = "${var.tags}-transit-gateway"
  }
}

# Create the Transit Gateway Attachment for the vpc
resource "aws_ec2_transit_gateway_vpc_attachment" "my_vpc_attachment" {
  subnet_ids         = [aws_subnet.public_subnet_1.id]
  transit_gateway_id = aws_ec2_transit_gateway.my_transit_gateway.id
  vpc_id             = aws_vpc.my_vpc.id
}

# Create a Route Table for the Transit Gateway
resource "aws_ec2_transit_gateway_route_table" "my_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.my_transit_gateway.id
  tags = {
    "Name" = "${var.tags}-Transit-Gateway-Route-table"
  }
}

# Create a default route for the Transit Gateway Route Table
resource "aws_ec2_transit_gateway_route" "default_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.my_route_table.id
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.my_vpc_attachment.id
  #blackhole = true
}