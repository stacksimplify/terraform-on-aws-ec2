# Resource: EC2 Instance
resource "aws_instance" "myec2" {
  ami = "ami-04d7457c43c292911"
  instance_type = "t3.micro"
  user_data = file("${path.module}/app1-install.sh")
  tags = {
    "Name" = "EC2Demo"
  }
}