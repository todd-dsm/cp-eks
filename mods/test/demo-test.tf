/*
  -----------------------------------------------------------------------------
                          Initialize/Declare Variables
  -----------------------------------------------------------------------------
*/
resource "aws_route53_zone" "test" {
  name = "yo.${var.dns_zone}"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.test.zone_id
  name    = "www.${aws_route53_zone.test.name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.web.public_ip]
}

resource "aws_route53_record" "user-dev" {
  zone_id = aws_route53_zone.test.zone_id
  name = "dev"
  type = "CNAME"
  ttl  = "5"

  weighted_routing_policy {
    weight = 10
  }

  set_identifier = "devs"
  records        = ["user-dev"]
}

/*
  -----------------------------------------------------------------------------
                                  EC2 Instance
  # Create a new instance of the latest Ubuntu 14.04 on an
  # t2.micro node with an AWS Tag naming it "HelloWorld"
  -----------------------------------------------------------------------------
*/
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = "thomas.pub"                    # Comment this line for demo drama

  subnet_id = "subnet-bfd942c6"
  associate_public_ip_address = true

  tags = {
    Name = "HelloWorld"
  }
}

/*
  -----------------------------------------------------------------------------
                                  Networking
  -----------------------------------------------------------------------------
*/
//resource "aws_key_pair" "sysadmin" {
//  key_name = var.builder
//  public_key = var.builder
//}
//
//resource "aws_key_pair" "builder" {
//  public_key = var.builder
//}

# -----------------------------------------------------------------------------
# Create a Security Group for the Instance
# -----------------------------------------------------------------------------
resource "aws_security_group" "ubuntu-ports" {
  name = "example-ports"
  # Inbound SSH from myOffice
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.officeIPAddr]
  }
  # Allow all outbound traffic: for now
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------
# Find the latest AMI; NOTE: MUST produce only 1 AMI ID.
# -----------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
