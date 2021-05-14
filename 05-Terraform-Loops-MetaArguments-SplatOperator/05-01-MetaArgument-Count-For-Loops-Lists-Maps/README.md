# Terraform For Loops, Lists, Maps and Count Meta-Argument

## Step-00: Pre-requisite Note
- We are using the `default vpc` in `us-east-1` region

## Step-01: Introduction
- Terraform Meta-Argument: `Count`
- **Terraform Lists & Maps**
  - List(string)
  - map(string)
- **Terraform for loops**
  - for loop with List
  - for loop with Map
  - for loop with Map Advanced
- **Splat Operators**
  - Legacy Splat Operator `.*.`
  - Generalized Splat Operator (latest)
  - Understand about Terraform Generic Splat Expression `[*]` when dealing with `count` Meta-Argument and multiple output values

## Step-02: c1-versions.tf 
- No changes

## Step-03: c2-variables.tf - Lists and Maps
```t
# AWS EC2 Instance Type - List
variable "instance_type_list" {
  description = "EC2 Instnace Type"
  type = list(string)
  default = ["t3.micro", "t3.small"]
}


# AWS EC2 Instance Type - Map
variable "instance_type_map" {
  description = "EC2 Instnace Type"
  type = map(string)
  default = {
    "dev" = "t3.micro"
    "qa"  = "t3.small"
    "prod" = "t3.large"
  }
}
```

## Step-04: c3-ec2securitygroups.tf and c4-ami-datasource.tf
- No changes to both files

## Step-05: c5-ec2instance.tf
```t
# How to reference List values ?
instance_type = var.instance_type_list[1]

# How to reference Map values ?
instance_type = var.instance_type_map["prod"]

# Meta-Argument Count
count = 2

# count.index
  tags = {
    "Name" = "Count-Demo-${count.index}"
  }
```

## Step-06: c6-outputs.tf
- for loop with List
- for loop with Map
- for loop with Map Advanced
```t

# Output - For Loop with List
output "for_output_list" {
  description = "For Loop with List"
  value = [for instance in aws_instance.myec2vm: instance.public_dns ]
}

# Output - For Loop with Map
output "for_output_map1" {
  description = "For Loop with Map"
  value = {for instance in aws_instance.myec2vm: instance.id => instance.public_dns}
}

# Output - For Loop with Map Advanced
output "for_output_map2" {
  description = "For Loop with Map - Advanced"
  value = {for c, instance in aws_instance.myec2vm: c => instance.public_dns}
}

# Output Legacy Splat Operator (latest) - Returns the List
output "legacy_splat_instance_publicdns" {
  description = "Legacy Splat Expression"
  value = aws_instance.myec2vm.*.public_dns
}  

# Output Latest Generalized Splat Operator - Returns the List
output "latest_splat_instance_publicdns" {
  description = "Generalized Splat Expression"
  value = aws_instance.myec2vm[*].public_dns
}
```

## Step-07: Execute Terraform Commands
```t
# Terraform Initialize
terraform init

# Terraform Validate
terraform validate

# Terraform Plan
terraform plan
Observations: 
1) play with Lists and Maps for instance_type

# Terraform Apply
terraform apply -auto-approve
Observations: 
1) Two EC2 Instances (Count = 2) of a Resource myec2vm will be created
2) Count.index will start from 0 and end with 1 for VM Names
3) Review outputs in detail (for loop with list, maps, maps advanced, splat legacy and splat latest)
```

## Step-08: Terraform Comments
- Single Line Comments - `#` and `//`
- Multi-line Commnets - `Start with /*` and `end with */`
- We are going to comment the legacy splat operator, which might be decommissioned in future versions
```t
# Output Legacy Splat Operator (latest) - Returns the List
/* output "legacy_splat_instance_publicdns" {
  description = "Legacy Splat Expression"
  value = aws_instance.myec2vm.*.public_dns
}  */
```

## Step-09: Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Files
rm -rf .terraform*
rm -rf terraform.tfstate*
```

