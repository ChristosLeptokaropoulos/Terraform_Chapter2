provider "aws" {
    region = "eu-central-1"
}

data "aws_ami" "ubuntu" {
    most_recent = true
    owners      = ["099720109477"] # Canonical

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }
}

resource "aws_instance" "example" { 
    ami           = data.aws_ami.ubuntu.id
    instance_type = "t3.micro"

    tags = {
        Name = "terraform-example"
    }
}