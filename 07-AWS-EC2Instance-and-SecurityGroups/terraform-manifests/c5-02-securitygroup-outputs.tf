# AWS EC2 Security Group Terraform Outputs

# Public Bastion Host Security Group Outputs
## public_bastion_sg_group_id
output "public_security_group_id" {
  description = "The ID of the security group"
  value       = module.Public-bastion-sg.security_group_id
}
## public_bastion_sg_group_vpc_id
output "Public_security_group_vpc_id" {
  description = "The VPC ID"
  value       = module.Public-bastion-sg.security_group_vpc_id
}

output "public_security_group_owner_id" {
  description = "The owner ID"
  value       = module.Public-bastion-sg.security_group_owner_id
}
## public_bastion_sg_group_name
output "public_security_group_name" {
  description = "The name of the security group"
  value       = module.Public-bastion-sg.security_group_name
}




# Private EC2 Instances Security Group Outputs

## private_sg_group_id
output "private_security_group_id" {
  description = "The ID of the security group"
  value       = module.private_sg.security_group_id
}
## private_sg_group_vpc_id
output "private_security_group_vpc_id" {
  description = "The VPC ID"
  value       = module.private_sg.security_group_vpc_id
}

## private_sg_group_name

output "private_security_group_name" {
  description = "The name of the security group"
  value       = module.private_sg.security_group_name
}

