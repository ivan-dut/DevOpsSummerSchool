provider "aws" {
    region = "eu-central-1"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# Last ami Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

data "template_file" "apache_script" {
  template = file("./user_data/scripts_apache.tpl")
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "myKey"       # Create "myKey" to AWS!!
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./myKey.pem"
  }
}

resource "aws_security_group" "port_http_https_ssh_access" {
  name        = "VPC port 80_443_22_access"
  description = "Allow VPC 80_443_22 inbound traffic from my IP and local2"

   ingress {
    description = "http traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }
  
  ingress {
    description = "https traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    description = "SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "port_80_443_22_access"
  }
}

resource "aws_instance" "web_app" { 
    ami                     = data.aws_ami.ubuntu.id
    instance_type           = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.port_http_https_ssh_access.id]
    key_name                = aws_key_pair.generated_key.key_name
    user_data               = data.template_file.apache_script.rendered
   
    tags = {
    Name = "Web Application"
  }
}
