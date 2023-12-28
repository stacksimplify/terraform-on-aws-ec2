# Terraform AWS RDS Database Variables
# Place holder file for AWS RDS Database

# DB Name
variable "db_name" {
  description = "AWS RDS Database Name"
  type        = string
}
# DB Instance Identifier
variable "db_instance_identifier" {
  description = "AWS RDS Database Instance Identifier"
  type        = string
}
# DB Username - Enable Sensitive flag
variable "db_username" {
  description = "AWS RDS Database Administrator Username"
  type        = string
}
# DB Password - Enable Sensitive flag
variable "db_password" {
  description = "AWS RDS Database Administrator Password"
  type        = string
  sensitive   = true
}


