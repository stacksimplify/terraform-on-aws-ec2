# AWS EC2 Instance Terraform Module
/*
# EC2 Instances that will be created in VPC Private Subnets
# App1 - EC2 Instances
module "ec2_private_app1" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.17.0"
  name = "${var.environment}-app1"
  ami = data.aws_ami.amzlinux2.id 
  instance_type = var.instance_type
  user_data = file("${path.module}/app1-install.sh")
  key_name = var.instance_keypair
  vpc_security_group_ids = [module.private_sg.this_security_group_id]    
  instance_count = 1
  subnet_ids = [
    module.vpc.private_subnets[0], 
    module.vpc.private_subnets[1],
    module.vpc.private_subnets[2]
    ]
  tags = local.common_tags
}
*/




# Bastion Host - EC2 Instance that will be created in VPC Public Subnet
module "ec2_public" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.17.0"
  # insert the 10 required variables here
  name = "${var.environment}-BastionHost"
  ami = data.aws_ami.amzlinux2.id 
  instance_type = var.instance_type
  key_name = var.instance_keypair
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.public_bastion_sg.this_security_group_id]    
  instance_count = 1
  tags = local.common_tags
}

