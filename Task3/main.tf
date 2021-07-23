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

data "template_file" "moodle_script" {
  template = file("./user_data/scripts_moodle.tpl")
  vars = {
    db_moodle_url     = module.db.db_instance_address
  }
}


#infrastructure
module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"

  name            = "moodle-vpc"
  cidr            = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.100.0/24", "10.0.101.0/24"]

  #enable_nat_gateway = true
  #single_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  
  tags = {
    Environment = "moodle"
  }
}


resource "aws_security_group" "port_http_ssh_access" {
  name        = "VPC port 80_22_access"
  description = "Allow VPC 80_22 inbound traffic from my IP and local2"
  vpc_id = module.vpc.vpc_id

   ingress {
    description = "web traffic"
    from_port   = 80
    to_port     = 80
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
    Name = "port_80_22_access"
  }
}

resource "aws_security_group" "port_mySQL_access" {
  name        = "VPC port 3306_access"
  description = "Allow VPC 3306 inbound traffic from my IP and local2"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "MySQL traffic"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = module.vpc.public_subnets_cidr_blocks
  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "port_3306_access"
  }
}
resource "aws_instance" "moodle_app" { 
    ami                     = data.aws_ami.ubuntu.id
    instance_type           = "t2.medium"
    subnet_id               = element(module.vpc.public_subnets, 0)
    vpc_security_group_ids  = [aws_security_group.port_http_ssh_access.id]
    key_name                = "key"
    user_data               = data.template_file.moodle_script.rendered
    #depends_on            = [module.db.moodledb]

    tags = {
    Name = "Moodle Application"
  }
}


module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = "moodledb"

  engine            = "mysql"
  engine_version    = "5.7.19"
  instance_class    = "db.t2.medium"
  allocated_storage = 5

  name     = "moodle"
  username = "moodle"
  password = "Perd0le!"
  port     = "3306"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.port_mySQL_access.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

 
  # DB subnet group
  subnet_ids = module.vpc.public_subnets

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  publicly_accessible = true
  skip_final_snapshot = true


  parameters = [
    {
      name = "character_set_client"
      value = "utf8"
    },
    {
      name = "character_set_server"
      value = "utf8"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}

