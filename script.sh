#/bin/bash 
sudo yum update -y 
sudo yum install docker -y 
sudo usermod -aG docker ec2-user
docker run -p 8080:80 nginx