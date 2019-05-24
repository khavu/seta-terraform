// AWS provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

// Config key_pair
resource "aws_key_pair" "test_key" {
  key_name   = "test_key"
  public_key = "${file("${var.aws_ssh_test_key_file}.pub")}"
}

// Config VPC network with access from internet
resource "aws_vpc" "test-vpc" {
   cidr_block = "${var.cidr_vpc}"
   enable_dns_hostnames = true
   enable_dns_support = true
   tags {
     Name = "test-vpc"
   }
 }

resource "aws_internet_gateway" "test-igw" {
   vpc_id = "${aws_vpc.test-vpc.id}"
   tags {
     Name = "test-igw"
   }
 }

resource "aws_subnet" "test-subnet-public" {
   cidr_block = "${var.cidr_subnet}"
   vpc_id = "${aws_vpc.test-vpc.id}"
   tags {
     Name = "test-subnet-public"
   }
}

resource "aws_route_table" "test-rtb-public" {
  vpc_id = "${aws_vpc.test-vpc.id}"
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.test-igw.id}"
  }
  tags {
    Name = "test-rtb-public"
  }
}

resource "aws_route_table_association" "test-rta-subnet-public" {
  subnet_id      = "${aws_subnet.test-subnet-public.id}"
  route_table_id = "${aws_route_table.test-rtb-public.id}"
}

// Config security group
resource "aws_security_group" "test-sg-efs" {
  name        = "test-sg-efs"
  description = "Security Group for Test"
  vpc_id      = "${aws_vpc.test-vpc.id}"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_subnet}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_subnet}"]
  }
}

resource "aws_security_group" "test-sg-instance" {
  name        = "test-sg-instance"
  description = "Security Group for Test"
  vpc_id      = "${aws_vpc.test-vpc.id}"

  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port   = 9100
      to_port     = 9100
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Config EFS service
resource "aws_efs_file_system" "test_efs" {
   creation_token = "test_efs"
   performance_mode = "generalPurpose"
   throughput_mode = "bursting"
   encrypted = "true"
 tags = {
     Name = "test_efs"
   }
 }

resource "aws_efs_mount_target" "test_mount_efs" {
    file_system_id  = "${aws_efs_file_system.test_efs.id}"
    subnet_id = "${aws_subnet.test-subnet-public.id}"
    security_groups = ["${aws_security_group.test-sg-efs.id}"]
}

// Create instance with VPC, Security Group, EFS
resource "aws_instance" "test" {
  ami                         = "ami-02eac2c0129f6376b"
  instance_type               = "t2.micro"
  key_name                    = "${aws_key_pair.test_key.key_name}"
  vpc_security_group_ids      = ["${aws_security_group.test-sg-instance.id}"]
  subnet_id                   = "${aws_subnet.test-subnet-public.id}"
  user_data                   = <<-EOF
                                #!/bin/bash
                                yum install -y epel-release
                                yum install -y ansible git
                                cd ~
                                echo "${aws_efs_file_system.test_efs.dns_name}" >> mount_point.txt
                                git clone "https://github.com/khavu/seta-ansible.git"
                                cd seta-ansible
                                ansible-playbook -K playbook.yml
                                EOF
  associate_public_ip_address = true
  tags {
    Name = "test"
  }
}
