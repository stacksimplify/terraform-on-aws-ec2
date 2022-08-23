# AWS EC2 Instance Terraform Module
# EC2 Instances that will be created in VPC Private Subnets
locals {
  multiple_instances = {
    one = {
      instance_type     = var.instance_type
      subnet_id         = element(module.vpc.private_subnets, 0)
  
    }

    two = {
      instance_type     = var.instance_type
      # availability_zone = element(module.vpc.azs, 2)
      subnet_id         = element(module.vpc.private_subnets, 1)
    }
  }
}

module "ec2_private" {
    source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.1.4"

  for_each = local.multiple_instances

  name = "${var.environment}-vm-${each.key}"

  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = each.value.instance_type
  # availability_zone      = each.value.availability_zone
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = [module.security_group.security_group_id]

  

  tags = local.tags
}
