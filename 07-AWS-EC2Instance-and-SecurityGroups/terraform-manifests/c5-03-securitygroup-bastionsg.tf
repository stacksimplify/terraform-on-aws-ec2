# AWS EC2 Security Group Terraform Module
# Security Group for Public Bastion Host
module "Public-bastion-sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"
 
  name = "public-bastion-sg"
  description = " Sg for bastion hosts with SSH port open for everybody."
  vpc_id = module.vpc.vpc_id

  #opening ingress traffic from the outside world
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]
  #egress traffic. Allowing all traffic


  egress_rules = ["all-all"]

  tags = local.common_tags

}