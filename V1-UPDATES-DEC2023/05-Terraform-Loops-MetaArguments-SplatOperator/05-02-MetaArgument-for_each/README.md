# Terraform for_each Meta-Argument with Functions toset, tomap
## Step-00: Pre-requisite Note
- We are using the `default vpc` in `us-east-1` region

## Step-01: Introduction
- `for_each` Meta-Argument
- `toset` function
- `tomap` function
- Data Source: aws_availability_zones

## Step-02: No changes to files
- c1-versions.tf
- c2-variables.tf
- c3-ec2securitygroups.tf
- c4-ami-datasource.tf

## Step-03: c5-ec2instance.tf
- To understand more about [for_each](https://www.terraform.io/docs/language/meta-arguments/for_each.html)

### Step-03-01: Availability Zones Datasource
```t
# Availability Zones Datasource
data "aws_availability_zones" "my_azones" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
```

### Step-03-02: EC2 Instance Resource
```t
# EC2 Instance
resource "aws_instance" "myec2vm" {
  ami = data.aws_ami.amzlinux2.id
  instance_type = var.instance_type
  user_data = file("${path.module}/app1-install.sh")
  key_name = var.instance_keypair
  vpc_security_group_ids = [ aws_security_group.vpc-ssh.id, aws_security_group.vpc-web.id   ]
  # Create EC2 Instance in all Availabilty Zones of a VPC  
  for_each = toset(data.aws_availability_zones.my_azones.names)
  availability_zone = each.key # You can also use each.value because for list items each.key == each.value
  tags = {
    "Name" = "For-Each-Demo-${each.key}"
  }
}
```

## Step-04: c6-outputs.tf
```t

# EC2 Instance Public IP with TOSET
output "instance_publicip" {
  description = "EC2 Instance Public IP"
  #value = aws_instance.myec2vm.*.public_ip   # Legacy Splat
  #value = aws_instance.myec2vm[*].public_ip  # Latest Splat
  value = toset([
      for myec2vm in aws_instance.myec2vm : myec2vm.public_ip
    ])  
}

# EC2 Instance Public DNS with TOSET
output "instance_publicdns" {
  description = "EC2 Instance Public DNS"
  #value = aws_instance.myec2vm[*].public_dns  # Legacy Splat
  #value = aws_instance.myec2vm[*].public_dns  # Latest Splat
  value = toset([
      for myec2vm in aws_instance.myec2vm : myec2vm.public_dns
    ])    
}

# EC2 Instance Public DNS with MAPS
output "instance_publicdns2" {
  value = tomap({
    for s, myec2vm in aws_instance.myec2vm : s => myec2vm.public_dns
    # S intends to be a subnet ID
  })
}
```

## Step-05: Execute Terraform Commands
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
1) Should fail with not creating EC2 Instance in 1 availability zone in region us-east-1
2) We will learn about fixing this in next two sections 05-03 and 05-04
3) Outputs not displayed as we failed during terraform apply. We will see and review outputs in section 05-04
```

## Step-06: Expected Error Message
```t
Error: Error launching source instance: Unsupported: Your requested instance type (t3.micro) is not supported in your requested Availability Zone (us-east-1e). Please retry your request by not specifying an Availability Zone or choosing us-east-1a, us-east-1b, us-east-1c, us-east-1d, us-east-1f.
	status code: 400, request id: 52e0e358-17a0-434b-80de-5bc5f956eedb

  on c5-ec2instance.tf line 35, in resource "aws_instance" "myec2vm":
  35: resource "aws_instance" "myec2vm" {

```

## Step-07: Clean-Up
```t
# Terraform Destroy
terraform destroy -auto-approve

# Clean-Up
rm -rf .terraform*
rm -rf terraform.tfstate*
```

## References
- [Terraform Functions](https://www.terraform.io/docs/language/functions/tolist.html)
- [Data Source: aws_availability_zones](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones)
- [for_each Meta-Argument](https://www.terraform.io/docs/language/meta-arguments/for_each.html)
- [tomap Function](https://www.terraform.io/docs/language/functions/tomap.html)
- [toset Function](https://www.terraform.io/docs/language/functions/toset.html)