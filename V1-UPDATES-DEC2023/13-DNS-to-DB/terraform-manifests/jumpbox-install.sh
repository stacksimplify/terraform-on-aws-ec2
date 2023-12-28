#! /bin/bash
sudo yum update -y
sudo rpm -e --nodeps mariadb-libs-*
sudo amazon-linux-extras enable mariadb10.5 
sudo yum clean metadata
sudo yum install -y mariadb
sudo mysql -V
sudo yum install -y telnet