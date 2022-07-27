resource "aws_instance" "myec2vm" {
  ami = data.aws_ami.amz_linux2.id
  instance_type = var.instance_type
  user_data = file("${path.module}/app1-install.sh")
  key_name = var.instance_keypair
  vpc_security_group_ids = [ aws_security_group.allow_ssh.id, aws_security_group.allow_web.id ]
  tags = {
    "Name" = "MyDemoEC2"
  }
}
