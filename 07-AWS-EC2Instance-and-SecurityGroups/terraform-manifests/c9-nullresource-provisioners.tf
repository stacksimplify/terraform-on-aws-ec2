# Create a Null Resource and Provisioners
resource "null_resource" "name" {
 depends_on=[module.ec2_public]

  connection {
    type     = "ssh"
    user     = "root"
    password = "${var.root_password}"
    host     = aws_eip.ec2_public_eip.public_ip
    private_key = file("private-key/NewTerraformkey.pem")
  }

  # ...
    provisioner "file" {
    source      = "private-key/NewTerraformkey.pem"
    destination = "/tmp/NewTerraformkey.pem"
  }

    provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /tmp/NewTerraformkey.pem"
    ]
  }

  provisioner "local-exec" {
    command = "echo Destroy time prov `date` >> destroy-time-prov.txt"
    working_dir = "local-exec-output-files/"
    when = destroy
    #on_failure = continue
  }  
 
}


## File Provisioner: Copies the terraform-key.pem file to /tmp/terraform-key.pem
## Remote Exec Provisioner: Using remote-exec provisioner fix the private key permissions on Bastion Host
## Local Exec Provisioner:  local-exec provisioner (Creation-Time Provisioner - Triggered during Create Resource)
## Local Exec Provisioner:  local-exec provisioner (Destroy-Time Provisioner - Triggered during deletion of Resource)
# Creation Time Provisioners - By default they are created during resource creations (terraform apply)
# Destory Time Provisioners - Will be executed during "terraform destroy" command (when = destroy)