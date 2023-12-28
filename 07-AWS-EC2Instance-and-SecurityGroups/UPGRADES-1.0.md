# Terraform Manifest Upgrades

## Step-01: c1-versions.tf
```t
# Terraform Block
terraform {
  required_version = ">= 1.6" # which means any version equal & above 0.14 like 0.15, 0.16 etc and < 1.xx
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
    }        
  }
}
```

## Step-02: c4-02-vpc-module.tf
```t
  source  = "terraform-aws-modules/vpc/aws"
  #version = "2.78.0"
  #version = "~> 2.78"
  version = "5.2.0"
```

## Step-03: c5-02-securitygroup-outputs.tf
- `this` is removed for all the Security Group Outputs
```t
# BEFORE
output "public_bastion_sg_group_id" {
  description = "The ID of the security group"
  value       = module.public_bastion_sg.this_security_group_id
}

#AFTER
output "public_bastion_sg_group_id" {
  description = "The ID of the security group"
  value       = module.public_bastion_sg.security_group_id
}
```

## Step-04: c5-03-securitygroup-bastionsg.tf
```t
  source  = "terraform-aws-modules/security-group/aws"
  #version = "3.18.0"
  version = "5.1.0"
```

## Step-05: c5-04-securitygroup-privatesg.tf
```t
  source  = "terraform-aws-modules/security-group/aws"
  #version = "3.18.0"
  version = "5.1.0"
```

## Step-06: c7-03-ec2instance-bastion.tf
```t
  source  = "terraform-aws-modules/ec2-instance/aws"
  #version = "2.17.0"
  version = "5.5.0"  
```

## Step-07: c7-04-ec2instance-private.tf
1. `count` meta-argument not supported for creating multiple instances 
2. We need to switch the code to `for_each` to support creating multiple instances
```t
# Change-1: Module Version
  source  = "terraform-aws-modules/ec2-instance/aws"
  #version = "2.17.0"
  version = "5.5.0"  

# Change-2: Change from count to for_each
1. count meta-argument not supported for creating multiple instances 
2. We need to switch the code to for_each to support creating multiple instances

# Changes as part of Module version from 2.17.0 to 5.5.0
  for_each = toset(["0", "1"])
  subnet_id =  element(module.vpc.private_subnets, tonumber(each.key))
  vpc_security_group_ids = [module.private_sg.security_group_id]

# BELOW CODE COMMENTED AS PART OF MODULE UPGRADE TO 5.5.0
/*  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1]
  ]  
  instance_count         = var.private_instance_count
  vpc_security_group_ids = [module.private_sg.this_security_group_id]    
*/
```

## Step-08: c7-02-ec2instance-outputs.tf
- Updated the outputs with `for loop` to support the `for_each` used for creating multiple `ec2_private` instances using `c7-04-ec2instance-private.tf`
```t

# Private EC2 Instances
## ec2_private_instance_ids
output "ec2_private_instance_ids" {
  description = "List of IDs of instances"
  #value       = [module.ec2_private.id]
  value = [for ec2private in module.ec2_private: ec2private.id ]   
}

## ec2_private_ip
output "ec2_private_ip" {
  description = "List of private IP addresses assigned to the instances"
  #value       = [module.ec2_private.private_ip]
  value = [for ec2private in module.ec2_private: ec2private.private_ip ]  
}
```

## Step-09: c8-elasticip.tf
```t
  # COMMENTED
  #instance = module.ec2_public.id[0]
  #vpc      = true

  # UPDATED
  instance = module.ec2_public.id
  domain = "vpc"
 
```