output "instance_publicip" {
    description = "ec2 instance public ip"
    value = aws_instance.myec2vm.public_ip
  
}

output "instance_publicdns" {
    description = "ec2 instance public ip"
    value = aws_instance.myec2vm.public_dns
  
}
