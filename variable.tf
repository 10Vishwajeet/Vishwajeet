variable "region" {
  default = "eu-north-1"
}

variable "vpc_cidr" {
  default = "192.168.0.0/16"
}

variable "public_subnet_cidr" {
  default = "192.168.0.0/22"
}

variable "private_subnet_cidr" {
  default = "192.168.4.0/22"
}

variable "public_az" {
  default = "eu-north-1a"
}

variable "private_az" {
  default = "eu-north-1b"
}

variable "ami_id" {
  default = "ami-0b2ab3a97a77bd35e"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  default = "AWS"
}



