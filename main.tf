provider "aws" {}

variable "app-cidr-block"{}
variable "app-subnet-1"{}
variable "env_prefix"{}
variable "avail_zone"{}
variable "app-instance"{}

resource "aws_vpc" "app_vpc"{
  cidr_block = var.app-cidr-block
  tags =  { Name: "${var.env_prefix}-vpc" }
}
resource "aws_subnet" "app_subnet_1" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = var.app-subnet-1
    availability_zone = var.avail_zone
    tags =  { name: "${var.env_prefix}-subnet-1" }
} 

resource "aws_internet_gateway" "app-igw"{
    vpc_id = aws_vpc.app_vpc.id
    tags =  { name: "${var.env_prefix}-igw" }
    
}

resource "aws_route_table" "app_route-table"{
    vpc_id = aws_vpc.app_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.app-igw.id
    }
    tags =  { name: "${var.env_prefix}-route-table-1" } 

}

resource "aws_route_table_association" "app-rta" {
    subnet_id   = aws_subnet.app_subnet_1.id
    route_table_id = aws_route_table.app_route-table.id
}
resource "aws_security_group" "app-security"{
    vpc_id = aws_vpc.app_vpc.id
    tags =  { Name: "${var.env_prefix}-security-grp-1" } 
    name = "app-secg"
    ingress {
        from_port = 22
        to_port = 22 
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        
    }
      ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }       
}

data "aws_ami" "app-ami-instance"{
    most_recent = true 
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-*-x86_64-gp2"]
    }
}
output "aws_ami_id" {
    value  =  data.aws_ami.app-ami-instance.id
}
resource "aws_instance" "app-instance"{
    ami = data.aws_ami.app-ami-instance.id
    instance_type = var.app-instance
    subnet_id = aws_subnet.app_subnet_1.id
    vpc_security_group_ids = [aws_security_group.app-security.id ]
    availability_zone =  var.avail_zone
    associate_public_ip_address = true
    key_name = "Newlogin"
    tags =  { Name: "${var.env_prefix}-instance-1" } 
    user_data =  <<EOF
                    #/bin/bash 
                    sudo yum update -y 
                    sudo yum install docker -y 
                    sudo usermod -aG docker ec2-user
                    docker run -p 8080:80 nginx
                 EOF
  }

