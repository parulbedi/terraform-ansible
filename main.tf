terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.62.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

# Create a Public Subnet
resource "aws_subnet" "my_public_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "my-public-subnet"
  }
}

# Create a IG
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my-igw"
  }
}


resource "aws_route_table" "my_rt" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }
    tags = {
        Name = "my-public-subnet-rt"
        
    }
}
resource "aws_route_table_association" "my_rt" {
    subnet_id = aws_subnet.my_public_subnet.id
    route_table_id = aws_route_table.my_rt.id

}

resource "aws_security_group" "my_sg" {
  name        = "my-sg"
  description = "Allow SSH & HTTP inbound connections"
  vpc_id = aws_vpc.my_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags = {
    Name = "my-sg"
  }
}


resource "aws_instance" "my_instance_control_node" {
  ami           = "ami-0aa2b7722dc1b5612"
  instance_type = "t2.medium"
  key_name = "instance-key"
  vpc_security_group_ids = [ aws_security_group.my_sg.id ]
  subnet_id = aws_subnet.my_public_subnet.id
  associate_public_ip_address = true
  tags = {
    Name = "my-control-node"
  }

 connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("instance-key.pem")
      host        = self.public_ip
      agent    = "false"
  }

provisioner "remote-exec" {
  inline = [
          "sudo apt-get update -y",
          "sudo apt-get upgrade -y",
          "sudo apt-get install ansible -y",
        
          "sudo chmod -R o+rwx /etc/ansible/hosts",
          "echo [webservers] >> /etc/ansible/hosts",
          "echo ${aws_instance.my_instance_manage_node.public_ip} >> /etc/ansible/hosts",
      ]
}

}

resource "null_resource" "copy_pem_file" {


  provisioner "file" {

   connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("instance-key.pem")
    host        = aws_instance.my_instance_control_node.public_ip
    agent    = "false"
  }
    source      = "instance-key.pem"
    destination = "/home/ubuntu/.ssh/instance-key.pem"
  }

}

resource "aws_instance" "my_instance_manage_node" {
  ami           = "ami-0aa2b7722dc1b5612"
  instance_type = "t2.medium"
  key_name = "instance-key"
  vpc_security_group_ids = [ aws_security_group.my_sg.id ]
  subnet_id = aws_subnet.my_public_subnet.id
  associate_public_ip_address = true
  tags = {
    Name = "my-manage-node"
  }
}