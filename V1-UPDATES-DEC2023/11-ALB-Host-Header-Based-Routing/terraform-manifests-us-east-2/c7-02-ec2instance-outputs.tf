# AWS EC2 Instance Terraform Outputs
# Public EC2 Instances - Bastion Host

## ec2_bastion_public_instance_ids
output "ec2_bastion_public_instance_ids" {
  description = "EC2 instance ID"
  value       = module.ec2_public.id
}

## ec2_bastion_public_ip
output "ec2_bastion_public_ip" {
  description = "Public IP address EC2 instance"
  value       = module.ec2_public.public_ip 
}

# Private EC2 Instances - App1
## ec2_private_instance_ids
output "ec2_private_instance_ids_app1" {
  description = "List of IDs of instances"
  value = [for ec2private in module.ec2_private_app1: ec2private.id ]   
}

## ec2_private_ip
output "ec2_private_ip_app1" {
  description = "List of private IP addresses assigned to the instances"
  value = [for ec2private in module.ec2_private_app1: ec2private.private_ip ]  
}


# Private EC2 Instances - App2
## ec2_private_instance_ids
output "ec2_private_instance_ids_app2" {
  description = "List of IDs of instances"
  value = [for ec2private in module.ec2_private_app2: ec2private.id ]   
}

## ec2_private_ip
output "ec2_private_ip_app2" {
  description = "List of private IP addresses assigned to the instances"
  value = [for ec2private in module.ec2_private_app2: ec2private.private_ip ]  
}





