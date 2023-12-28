/*
# Output Values
### VPC Output Values
# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}
# CIDR blocks
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}
# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}
# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}
# AZs
output "azs" {
  description = "A list of availability zones spefified as argument to this module"
  value       = module.vpc.azs
}

### EC2 Security Group Output Values
# Private EC2 Instances Security Group Outputs
output "private_sg_group_id" {
  description = "The ID of the security group"
  value       = module.private_sg.this_security_group_id
}
output "private_sg_group_vpc_id" {
  description = "The VPC ID"
  value       = module.private_sg.this_security_group_vpc_id
}
output "private_sg_group_name" {
  description = "The name of the security group"
  value       = module.private_sg.this_security_group_name
}

# Public Bastion Host Security Group Outputs
output "public_bastion_sg_group_id" {
  description = "The ID of the security group"
  value       = module.public_bastion_sg.this_security_group_id
}
output "ssh_sg_group_vpc_id" {
  description = "The VPC ID"
  value       = module.public_bastion_sg.this_security_group_vpc_id
}
output "ssh_sg_group_name" {
  description = "The name of the security group"
  value       = module.public_bastion_sg.this_security_group_name
}

### EC2 Instance Output Values
# Private EC2 Instances
output "ec2_private_instance_ids" {
  description = "List of IDs of instances"
  value       = module.ec2_private_app1.id
}
output "ec2_private_ip" {
  description = "List of private ip address assigned to the instances"
  value       = module.ec2_private_app1.private_ip
}

# Public EC2 Instances - Bastion Host
output "ec2_bastion_public_instance_ids" {
  description = "List of IDs of instances"
  value       = module.ec2_public.id
}
output "ec2_bastion_public_ip" {
  description = "List of Public ip address assigned to the instances"
  value       = module.ec2_public.public_ip
}

# ALB Application Load Balancer Outputs
# https://github.com/terraform-aws-modules/terraform-aws-alb/blob/master/examples/complete-alb/outputs.tf
output "alb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = module.alb.this_lb_dns_name
}

output "alb_http_tcp_listener_arns" {
  description = "The ARN of the TCP and HTTP load balancer listeners created."
  value       = module.alb.http_tcp_listener_arns
}


# Route53 Zone Outputs
output "route53_domain" {
  value = data.aws_route53_zone.mydomain.name
}

# ACM Outputs
output "this_acm_certificate_arn" {
  description = "The ARN of the certificate"
  value       = module.acm.this_acm_certificate_arn
}

output "this_acm_certificate_domain_validation_options" {
  description = "A list of attributes to feed into other resources to complete certificate validation. Can have more than one element, e.g. if SANs are defined. Only set if DNS-validation was used."
  value       = module.acm.this_acm_certificate_domain_validation_options
}

output "this_acm_certificate_validation_emails" {
  description = "A list of addresses that received a validation E-Mail. Only set if EMAIL-validation was used."
  value       = module.acm.this_acm_certificate_validation_emails
}

output "validation_route53_record_fqdns" {
  description = "List of FQDNs built using the zone domain and name."
  value       = module.acm.validation_route53_record_fqdns
}

output "distinct_domain_names" {
  description = "List of distinct domains names used for the validation."
  value       = module.acm.distinct_domain_names
}

output "validation_domains" {
  description = "List of distinct domain validation options. This is useful if subject alternative names contain wildcards."
  value       = module.acm.validation_domains
}

*/
