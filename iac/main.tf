terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region  = var.aws_region
  profile = "cloud-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {}

data "aws_subnet" "default" {
  filter {
    name   = "availability-zone"
    values = [data.aws_availability_zones.available.names[0]]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_security_group" "ssh_sg" {
  name   = "allow_ssh_worker"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # security_groups = [aws_security_group.ssh_sg.id]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "worker-sg" }
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform_key"
  public_key = file("~/.ssh/cloud-1.pub")
}

resource "aws_instance" "worker" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids      = [aws_security_group.ssh_sg.id]
  key_name                    = aws_key_pair.terraform_key.key_name
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data.d/user_data_worker.sh")

  tags = { Name = "worker" }
}

resource "aws_instance" "master" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  key_name               = aws_key_pair.terraform_key.key_name

  tags = { Name = "master" }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/cloud-1")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "~/.ssh/cloud-1"
    destination = "/home/ubuntu/.ssh/cloud-1"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo chmod 600 /home/ubuntu/.ssh/cloud-1",
      "sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/cloud-1",
    ]
  }

  user_data = file("${path.module}/user_data.d/user_data_master.sh")
}

resource "terraform_data" "configure_ansible" {
  input = {
    master_id = aws_instance.master.id
    worker_ip = aws_instance.worker.public_ip
  }

  triggers_replace = [
    aws_instance.master.id,
    aws_instance.worker.public_ip,
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/cloud-1")
    host        = aws_instance.master.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "if [ -d /home/ubuntu/cloud-1/.git ]; then git -C /home/ubuntu/cloud-1 pull --ff-only; else git clone https://${var.github_token}@github.com/moha-bekh/cloud-1.git /home/ubuntu/cloud-1; fi",
      "printf '%s\n' '[worker]' 'worker ansible_host=${self.input.worker_ip} ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/.ssh/cloud-1' > /home/ubuntu/cloud-1/cac/inventory.ini",
      "sed -i 's|^db_host:.*|db_host: \"{{ ansible_host | default(inventory_hostname) }}\"|' /home/ubuntu/cloud-1/cac/group_vars/all.yml",
      "sudo chown -R ubuntu:ubuntu /home/ubuntu/cloud-1",
    ]
  }
}

resource "aws_ebs_volume" "worker_volume" {
  availability_zone = aws_instance.worker.availability_zone
  size              = 8
  type              = "gp3"

  tags = {
    Name = "worker-ebs"
  }
}

resource "aws_volume_attachment" "worker_volume_attach" {
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.worker_volume.id
  instance_id  = aws_instance.worker.id
  force_detach = true
}
