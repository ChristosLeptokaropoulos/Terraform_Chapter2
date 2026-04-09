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
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
                #!/bin/bash
                cd /home/ubuntu
                echo "Hello, World" > index.xhtml
                nohup busybox httpd -f -p 8080 -h /home/ubuntu &
                EOF

    user_data_replace_on_change = true

    tags = {
        Name = "terraform-example"
    }
}

resource "aws_security_group" "instance" { 
    name = "terraform-example-instance"

    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_launch_template" "example" {
    image_id        = data.aws_ami.ubuntu.id
    instance_type   = "t3.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]
    
    user_data = base64encode(<<-EOF
                #!/bin/bash
                echo "Hello, World" > index.xhtml
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
    )

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "example" {
    launch_template {
        id      = aws_launch_template.example.id
        version = "$Latest"
    }
    vpc_zone_identifier  = data.aws_subnets.default.ids

    min_size = 2
    max_size = 10
    
    tag {
        key                 = "Name"
        value               = "terraform-asg-example"
        propagate_at_launch = true
    }
}

data "aws_subnets" "default" { 
    filter{
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

data "aws_vpc" "default"{ 
    default = true
}