variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "ami_id" {
  type    = string
  default = "ami-05b5a865c3579bbc4"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "github_token" {
  type      = string
  sensitive = true
}
