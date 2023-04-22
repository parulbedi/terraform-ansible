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
     # host       = aws_instance.my_instance_control_node.public_ip
      host        = self.public_ip
  }

  # provisioner "file" {
  #   source      = "instance-key.pem"
  #   destination = "../instance-key.pem"
  # }

  # provisioner "local-exec" {
  #   command = "chmod 700 instance-key.pem"
  #   command = "scp -i instance-key.pem ubuntu@${aws_instance.my_instance_control_node.public_ip} instance-key.pem :/home/ubuntu/"

  # }


# provisioner "remote-exec" {
#   command = <<-EOT
#           sudo apt-get update -y
#           sudo apt-get upgrade -y
#           sudo apt-get install ansible -y
#           sudo chmod -R o+rwx /etc/ansible/hosts
#       EOT
# }


provisioner "remote-exec" {
  inline = [
          "sudo apt-get update -y",
          "sudo apt-get upgrade -y",
          "sudo apt-get install ansible -y",
          "sudo chmod -R o+rwx /etc/ansible/hosts",
          "echo [webservers] >> /etc/ansible/hosts",
          "echo ${aws_instance.my_instance_manage_node.public_ip} >> /etc/ansible/hosts",
          "ls"
      ]
}

  # provisioner "file" {
  #   source      = "instance-key.pem"
  #   destination = "/tmp/instance-key.pem"
  # } 

# provisioner "remote-exec" {
#     inline = [
#       "sudo apt-add-repository ppa:ansible/ansible -y",
#       "sudo apt-get update 
#       "sudo apt-get upgrade -y",
#       "sudo apt install ansible -y",
#       "sudo chmod -R o+rwx /etc/ansible/hosts"
#     ]
# }


  # provisioner "remote-exec" {
  #   inline = [
	#     # "sudo apt-get update",
  #     # "sudo apt-get install apache2 -y",
	#     # "sudo systemctl start apache2",
  #     "sudo apt-add-repository ppa:ansible/ansible -y",
  #     "sudo apt-get update -y",
  #     "sudo apt-get upgrade -y",
  #     "sudo apt install ansible -y",
  #     # "sudo chmod -R  /etc/ansible/hosts"
  #     # "sudo chmod -R o+rwx /etc/ansible/hosts"

  #   ]
  #   on_failure = "continue"
  # }


# provisioner "file" {
#     # command = "sudo chmod -R o+rwx /etc/ansible/hosts"
#     destination = "../ansible/hosts"
#     content    = <<-EOF
#     [webservers]
#     ${aws_instance.my_instance_manage_node.public_ip}
#   EOF
# }



# ===================================================
#   provisioner "file" {
#     source      = "terraform.tfstate.backup"
#     destination = "/tmp/"
#   } 
# ===================================================
#   provisioner "file" {
#     source      = "configure.sh"
#     destination = "/tmp/configure.sh"
#   }
#   provisioner "remote-exec" {
#     connection {
#       host        = aws_instance.my_instance_control_node.public_ip
#       type        = "ssh"
#       user        = "ubuntu"
#       agent       = false
#       private_key = file("instance-key.pem")
#     }
#     inline = [
#       "chmod +x /tmp/configure.sh",
#       "/tmp/configure.sh",
#       "logout",
#     ]
#   }
}

resource "null_resource" "copy-test-file" {

# provisioner "remote-exec" {

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = file("instance-key.pem")
#     host        = aws_instance.my_instance_control_node.public_ip
#   }

# }

  provisioner "file" {

   connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("instance-key.pem")
    host        = aws_instance.my_instance_control_node.public_ip
  }
    source      = "instance-key.pem"
    destination = "/home/ubuntu/instance-key.pem"
  }
}

# resource "local_file" "inventory" {
#   filename   = "/etc/ansible/hosts"
#   content    = <<EOF
#   webservers
#   ${aws_instance.my_instance_manage_node.public_ip}
#   EOF
# }

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

# resource "local_file" "inventory" {
#   filename   = "../ansible/hosts"
#   content    = "hello"
# }

# resource "local_file" "inventory" {
#   filename   = "../ansible/hosts"
#   content    = <<-EOF
#     [webservers]
#     ${aws_instance.my_instance_manage_node.public_ip}
#   EOF
# }