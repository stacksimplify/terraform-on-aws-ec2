# Create a Null Resource and Provisioners
resource "null_resource" "name" {
  depends_on = [module.ec2_public, aws_eip.bastion_eip]
  # Connection Block for Provisioners to connect to EC2 Instance
  connection {
    type = "ssh"
    host = aws_eip.bastion_eip.public_ip
    user = "ec2-user"
    password = ""
    private_key = file("private-key/terraform-key.pem")
  } 

 # Copies the terraform-key.pem file to /home/ec2-user/terraform-key.pem
  provisioner "file" {
    source      = "private-key/terraform-key.pem"
    destination = "/home/ec2-user/terraform-key.pem"
  }  

# Using remote-exec provisioner fix the private key permissions
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /home/ec2-user/terraform-key.pem"
    ]
  }  
}

