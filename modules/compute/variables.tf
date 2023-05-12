# Define the variables
variable "vpc_id" {}
variable "subnet_ids" {}
variable "ami_id" {}
variable "instance_type" {}
variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}
variable "tags" {}
variable "vpc_cidr_block"{}
variable "subnet_a" {}
variable "subnet_b" {}


#variables for availability zone
variable "availability_zone" {
    description = "Availability zone"
    default = ["us-west-1a","us-west-1b"]
    type = list
}


# #variables for instnace_type
# variable "instance_type" {
#   description = "The EC2 instance type for the web servers."
#   default     = ["t2.micro","t2.medium"]
#   type = list
# }

# #variable for ami 
# variable "ami_id" {
#   description = "The AMI ID for the web servers."
#   default     = {
#      "linux":"ami-0c55b159cbfafe1f0"
#      "ubuntu":"ami-0c55b159cbfafe1f0"
#      "RHEL":"ami-0c55b159cbfafe1f0"
#      }
#      type = map
# }

# #variables for autoscaling group size
# variable "min_size" {
#   description = "The minimum number of instances in the web server autoscaling group."
#   default     = 2
# }

# variable "max_size" {
#   description = "The maximum number of instances in the web server autoscaling group."
#   default     = 4
# }

#variable for key pair name
variable "key_name" {
  default = "papy.oregon"
}

#Variables for db-tier. These variable will define all the db configurations

variable "db_name" {
  default = "my_rds_instance"
  type = string
}

variable "db_user" {}

variable "db_password" {}

#variable for db_instance_class
variable "db_class" {
  description = "The RDS instance class for the database."
  default     = "db.t2.micro"
  type = string
}

variable "db_engine" {}

variable "db_engine_version" {
  description = "The database engine version for the RDS instance."
  default     = "5.7"
  type = string
}

variable "db_allocated_storage" {
  description = "The amount of storage allocated to the RDS instance."
  default     = "20"
  type = string
}

# variable "db_subnet_group_name" {
#   description = "The name of the database subnet group."
#   default     = "web_group"
# }

