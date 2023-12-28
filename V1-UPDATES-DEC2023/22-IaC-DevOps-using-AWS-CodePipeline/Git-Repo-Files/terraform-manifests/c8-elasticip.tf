# Create Elastic IP for Bastion Host
# Resource - depends_on Meta-Argument
resource "aws_eip" "bastion_eip" {
  depends_on = [ module.ec2_public, module.vpc ]
  tags = local.common_tags
  # COMMENTED
  #instance = module.ec2_public.id[0]
  #vpc      = true

  # UPDATED
  instance = module.ec2_public.id
  domain = "vpc"      
}
