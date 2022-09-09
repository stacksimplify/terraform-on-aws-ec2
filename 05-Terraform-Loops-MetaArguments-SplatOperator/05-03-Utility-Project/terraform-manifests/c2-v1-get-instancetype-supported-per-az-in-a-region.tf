# Datasource
data "aws_ec2_instance_type_offerings" "my_ins_type1" {
  filter {
    name   = "instance-type"
    values = ["t3.micro"]
  }

  filter {
    name   = "location"
    values = ["us-east-1a"]
    # values = ["us-east-1a"]
  }

  location_type = "availability-zone"
}
# Output

output "output_v1" {
  value = data.aws_ec2_instance_type_offerings.my_ins_type1.instance_types
  
}
