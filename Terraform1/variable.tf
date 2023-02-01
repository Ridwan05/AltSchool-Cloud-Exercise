variable "user_data" {
  type    = string
  default = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo You are accessing my server $(hostname -f) > /var/www/html/index.html'
                sudo systemctl restart apache2
                EOF

}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ami" {
  type    = string
  default = "ami-0778521d914d23bc1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"

}

variable "availability_zone" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "cidr_blocks" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "domain" {
  type    = string
  default = "ridwandemo.me"
}