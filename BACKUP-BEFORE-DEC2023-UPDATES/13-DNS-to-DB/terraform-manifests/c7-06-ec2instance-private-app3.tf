# AWS EC2 Instance Terraform Module
# EC2 Instances that will be created in VPC Private Subnets for App2
module "ec2_private_app3" {
  depends_on = [ module.vpc ] # VERY VERY IMPORTANT else userdata webserver provisioning will fail
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.17.0"
  # insert the 10 required variables here
  name                   = "${var.environment}-app3"
  ami                    = data.aws_ami.amzlinux2.id
  instance_type          = var.instance_type
  key_name               = var.instance_keypair
  #monitoring             = true
  #vpc_security_group_ids = [module.private_sg.this_security_group_id]
  vpc_security_group_ids = [module.private_sg.security_group_id]  
  #subnet_id              = module.vpc.public_subnets[0]  
  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]  
  instance_count         = var.private_instance_count
  #user_data = file("${path.module}/app3-ums-install.tmpl") - THIS WILL NOT WORK, use Terraform templatefile function as below.
  #https://www.terraform.io/docs/language/functions/templatefile.html
  user_data =  templatefile("app3-ums-install.tmpl",{rds_db_endpoint = module.rdsdb.db_instance_address})    
  tags = local.common_tags
}


