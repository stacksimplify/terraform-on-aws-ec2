
# Input Variables
# AWS Region
variable "aws_region" {
  description = "Region of aws resources"
  type = string
  default = "us-east-1"

}
# AWS EC2 Instance Type
variable "instance_type" {
  description = "EC2 instance type"
  type = string
  default = "t2.micro"

  
}

# AWS EC2 Instance Key Pair

variable "instance_keypair" {
  description = "aws keypair to login"
  type = string
  default = "NewTerraformkey"
  
}

variable "instance_type_list" {
  description = "instance type while using list"
  type = list(string)
  default = [ "t3.micro" , "t2.small"]

}

variable "instance_type_map" {
  description = "instance type while using list"
  type = map(string)
  default = {
    "dev" = "t3.micro"
    "qa" = "t3.small"
    "prod" = "t3.large"
  }
}
