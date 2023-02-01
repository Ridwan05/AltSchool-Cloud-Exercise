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

resource "aws_subnet" "subnets" {
  for_each = {
    "Subnet1" = {
      cidr_block        = var.cidr_blocks[0]
      availability_zone = var.availability_zone[0]
      tags              = { "Name" = "Subnet1" }
    }
    "Subnet2" = {
      cidr_block        = var.cidr_blocks[1]
      availability_zone = var.availability_zone[1]
      tags              = { "Name" = "Subnet2" }
    }
    "Subnet3" = {
      cidr_block        = var.cidr_blocks[2]
      availability_zone = var.availability_zone[2]
      tags              = { "Name" = "Subnet3" }
    }
  }
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  tags              = each.value.tags

}

resource "aws_route_table_association" "myRtb" {
  for_each = {
    "a" = { subnet_id = aws_subnet.subnets["Subnet1"].id }
    "b" = { subnet_id = aws_subnet.subnets["Subnet2"].id }
    "c" = { subnet_id = aws_subnet.subnets["Subnet3"].id }
  }
  subnet_id      = each.value.subnet_id
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


resource "aws_instance" "Servers" {
  for_each = {
    "Server1" = {
      subnet_id = aws_subnet.subnets["Subnet1"].id
      tags      = { "Name" = "Server1" }
    }
    "Server2" = {
      subnet_id = aws_subnet.subnets["Subnet2"].id
      tags      = { "Name" = "Server2" }
    }
    "Server3" = {
      subnet_id = aws_subnet.subnets["Subnet3"].id
      tags      = { "Name" = "Server3" }
    }
  }
  tags                        = each.value.tags
  security_groups             = [aws_security_group.ec2web_access.id]
  subnet_id                   = each.value.subnet_id
  ami                         = var.ami
  instance_type               = var.instance_type
  associate_public_ip_address = "true"
  key_name                    = "rid"
  # user_data                   = var.user_data

}

resource "aws_lb" "my_elb" {
  name               = "my-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elbweb_access.id]
  subnets = [
    aws_subnet.subnets["Subnet1"].id,
    aws_subnet.subnets["Subnet2"].id,
    aws_subnet.subnets["Subnet3"].id
  ]
  depends_on = [
    aws_instance.Servers
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

resource "aws_lb_target_group_attachment" "my_target" {
  for_each = {
    "target1" = { target_id = aws_instance.Servers["Server1"].id }
    "target2" = { target_id = aws_instance.Servers["Server2"].id }
    "target3" = { target_id = aws_instance.Servers["Server3"].id }
  }
  target_group_arn = aws_lb_target_group.my_tgtgrp.arn
  target_id        = each.value.target_id
  port             = 80
}

resource "local_file" "IPs" {
  filename = "host-inventory"
  content  = <<EOT
  ${aws_instance.Servers["Server1"].public_ip}
  ${aws_instance.Servers["Server2"].public_ip}
  ${aws_instance.Servers["Server3"].public_ip}
  EOT
}


resource "aws_route53_zone" "myzone" {
  name = var.domain
  tags = {
    "Name" = "myzone"
  }
}

resource "aws_route53_record" "terraform-test" {
  zone_id = aws_route53_zone.myzone.zone_id
  name    = "terraform-test.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_lb.my_elb.dns_name
    zone_id                = aws_lb.my_elb.zone_id
    evaluate_target_health = true
  }
}