provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "vscode"
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "MyVPC"
  }
}

resource "aws_internet_gateway" "my_gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    "Name" = "Mygw"
  }
}

resource "aws_route_table" "my_rtb" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gw.id
  }

  tags = {
    "Name" = "myRtb"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "Subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    "Name" = "Subnet2"
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    "Name" = "Subnet3"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.my_rtb.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.my_rtb.id
}
resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.my_rtb.id
}

resource "aws_security_group" "ec2web_access" {
  name        = "allow_ec2web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.my_vpc.cidr_block]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "ec2web_access"
  }
}

resource "aws_security_group" "elbweb_access" {
  name        = "allow_elbweb_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "elbweb_access"
  }
}

resource "aws_instance" "one" {
  ami                         = "ami-0778521d914d23bc1"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id                   = aws_subnet.subnet1.id
  security_groups             = [aws_security_group.ec2web_access.id]
  key_name                    = "rid"

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo You are accessing my server $(hostname -f) > /var/www/html/index.html'
                sudo systemctl restart apache2
                EOF

  tags = {
    "Name" = "Server1"
  }
}
resource "aws_instance" "two" {
  ami                         = "ami-0778521d914d23bc1"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id                   = aws_subnet.subnet2.id
  security_groups             = [aws_security_group.ec2web_access.id]
  key_name                    = "rid"

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo You are accessing my server $(hostname -f) > /var/www/html/index.html'
                sudo systemctl restart apache2
                EOF

  tags = {
    "Name" = "Server2"
  }
}
resource "aws_instance" "three" {
  ami                         = "ami-0778521d914d23bc1"
  instance_type               = "t2.micro"
  associate_public_ip_address = "true"
  subnet_id                   = aws_subnet.subnet3.id
  security_groups             = [aws_security_group.ec2web_access.id]
  key_name                    = "rid"

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo You are accessing my server $(hostname -f) > /var/www/html/index.html'
                sudo systemctl restart apache2
                EOF

  tags = {
    "Name" = "Server3"
  }
}

resource "aws_lb" "my_elb" {
  name               = "my-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elbweb_access.id]
  subnets = [
    aws_subnet.subnet1.id,
    aws_subnet.subnet2.id,
    aws_subnet.subnet3.id
  ]
  depends_on = [
    aws_instance.one,
    aws_instance.two,
    aws_instance.three
  ]
  tags = {
    "Name" = "MyElb"
  }
}

resource "aws_lb_target_group" "my_tgtgrp" {
  name     = "my-tgtgrp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_lb_listener" "my_elb" {
  load_balancer_arn = aws_lb.my_elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tgtgrp.arn
  }
}

resource "aws_lb_target_group_attachment" "my_tgtgrp1" {
  target_group_arn = aws_lb_target_group.my_tgtgrp.arn
  target_id        = aws_instance.one.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "my_tgtgrp2" {
  target_group_arn = aws_lb_target_group.my_tgtgrp.arn
  target_id        = aws_instance.two.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "my_tgtgrp3" {
  target_group_arn = aws_lb_target_group.my_tgtgrp.arn
  target_id        = aws_instance.three.id
  port             = 80
}


