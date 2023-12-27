# Meta-Argument for_each with AZ Instance Type Check

## Step-00: Pre-requisite Note
- We are using the `default vpc` in `us-east-1` region

## Step-01: Introduction
- Implement the fix for issue we have faced in `section-05-02` with fix we have developed in `section-05-03`

## Step-02: c7-get-instancetype-supported-per-az-in-a-region.tf
- Copy this from previous `05-03-Utility-Project` from file named  `c2-v3-get-instancetype-supported-per-az-in-a-region.tf`
```t
# Get List of Availability Zones in a Specific Region
# Region is set in c1-versions.tf in Provider Block
data "aws_availability_zones" "my_azones" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Check if that respective Instance Type is supported in that Specific Region in list of availability Zones
# Get the List of Availability Zones in a Particular region where that respective Instance Type is supported
data "aws_ec2_instance_type_offerings" "my_ins_type" {
for_each=toset(data.aws_availability_zones.my_azones.names)
  filter {
    name   = "instance-type"
    values = ["t3.micro"]
  }
  filter {
    name   = "location"
    values = [each.key]
  }
  location_type = "availability-zone"
}


# Basic Output: All Availability Zones mapped to Supported Instance Types
output "output_v3_1" {
 value = { for az, details in data.aws_ec2_instance_type_offerings.my_ins_type :
  az => details.instance_types }   
}

# Filtered Output: Exclude Unsupported Availability Zones
output "output_v3_2" {
  value = { for az, details in data.aws_ec2_instance_type_offerings.my_ins_type :
  az => details.instance_types if length(details.instance_types) != 0 }
}

# Filtered Output: with Keys Function - Which gets keys from a Map
# This will return the list of availability zones supported for a instance type
output "output_v3_3" {
  value = keys({ for az, details in data.aws_ec2_instance_type_offerings.my_ins_type :
  az => details.instance_types if length(details.instance_types) != 0 }) 
}

# Filtered Output: As the output is list now, get the first item from list (just for learning)
output "output_v3_4" {
  value = keys({ for az, details in data.aws_ec2_instance_type_offerings.my_ins_type :
  az => details.instance_types if length(details.instance_types) != 0 })[0]
}
```

## Step-03: c5-ec2instance.tf
### Step-03-01: Update the `for_each` statement to new one 
```t
  for_each = toset(keys({ for az, details in data.aws_ec2_instance_type_offerings.my_ins_type :
  az => details.instance_types if length(details.instance_types) != 0 }))
```
### Step-03-02: Final look of c5-ec2-instance.tf
```t
# EC2 Instance
resource "aws_instance" "myec2vm" {
  ami = data.aws_ami.amzlinux2.id
  instance_type = var.instance_type
  user_data = file("${path.module}/app1-install.sh")
  key_name = var.instance_keypair
  vpc_security_group_ids = [ aws_security_group.vpc-ssh.id, aws_security_group.vpc-web.id   ]
  # Create EC2 Instance in all Availabilty Zones of a VPC  
  #for_each = toset(data.aws_availability_zones.my_azones.names)
  for_each = toset(keys({ for az, details in data.aws_ec2_instance_type_offerings.my_ins_type :
  az => details.instance_types if length(details.instance_types) != 0 }))
  availability_zone = each.key # You can also use each.value because for list items each.key == each.value
  tags = {
    "Name" = "For-Each-Demo-${each.key}"
  }
}
```

## Step-04: Execute Terraform Commands
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve
Observations:
1. Verify Outputs
2. Verify EC2 Instances created via AWS Management Console
```


## Step-05: Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Delete Files
rm -rf .terraform*
rm -rf terraform.tfstate*
```