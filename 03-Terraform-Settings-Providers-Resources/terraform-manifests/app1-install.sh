#!/bin/bash
sudo dnf update -y
sudo dnf install -y httpd
sudo systemctl enable httpd
sudo systemctl start httpd  

echo '<h1>Welcome to StackSimplify - APP-1</h1>' | sudo tee /var/www/html/index.html

sudo mkdir -p /var/www/html/app1
echo '<!DOCTYPE html><html><body style="background-color:rgb(250, 210, 210);"><h1>Welcome to Stack Simplify - APP-1</h1><p>Terraform Demo</p><p>Application Version: V1</p></body></html>' | sudo tee /var/www/html/app1/index.html