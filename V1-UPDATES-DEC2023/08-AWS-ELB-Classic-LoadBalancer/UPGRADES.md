# Terraform Manifest Upgrades

 ## Step-01: c10-02-ELB-classic-loadbalancer.tf
 ```t
 # Terraform AWS Classic Load Balancer (ELB-CLB)
module "elb" {
  source  = "terraform-aws-modules/elb/aws"
  #version = "2.5.0"
  version = "4.0.1"
  name = "${local.name}-myelb"
  subnets         = [
    module.vpc.public_subnets[0],
    module.vpc.public_subnets[1]
  ]
  #security_groups = [module.loadbalancer_sg.this_security_group_id]
  security_groups = [module.loadbalancer_sg.security_group_id]
  #internal        = false

  listener = [
    {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
    },
    {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 81
      lb_protocol       = "HTTP"
    },
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  # ELB attachments
  number_of_instances = var.private_instance_count
  #instances           = [module.ec2_private.id[0],module.ec2_private.id[1]]
  instances = [for ec2private in module.ec2_private: ec2private.id ]  
  tags = local.common_tags
}
 ```

 ## Step-02: c10-03-ELB-classic-loadbalancer-outputs.tf
 ```t
 # Terraform AWS Classic Load Balancer (ELB-CLB) Outputs
output "elb_id" {
  description = "The name of the ELB"
  value       = module.elb.elb_id
}

output "elb_name" {
  description = "The name of the ELB"
  value       = module.elb.elb_name
}

output "elb_dns_name" {
  description = "The DNS name of the ELB"
  value       = module.elb.elb_dns_name
}

output "elb_instances" {
  description = "The list of instances in the ELB (if may be outdated, because instances are attached using elb_attachment resource)"
  value       = module.elb.elb_instances
}

output "elb_source_security_group_id" {
  description = "The ID of the security group that you can use as part of your inbound rules for your load balancer's back-end application instances"
  value       = module.elb.elb_source_security_group_id
}

output "elb_zone_id" {
  description = "The canonical hosted zone ID of the ELB (to be used in a Route 53 Alias record)"
  value       = module.elb.elb_zone_id
}
 ```