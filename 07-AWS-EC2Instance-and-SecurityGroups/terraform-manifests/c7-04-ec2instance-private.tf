# AWS EC2 Instance Terraform Module
# EC2 Instances that will be created in VPC Private Subnets
module "ec2_private" {
  depends_on = [module.vpc]
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.17.0"
  # insert the 10 required variables here
  name                   = "${var.environment}-privatevm"
  instance_count         = var.private_instance_count
  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = var.instance_type
  key_name               = var.instance_keypair
  #monitoring             = true
  subnet_ids              = module.vpc.private_subnets
  vpc_security_group_ids = [module.public_bastion_sg.this_security_group_id]
  user_data = file("${path.module}/app1-install.sh")
  tags = local.common_tags
}



