### Pass your access keys and aws access keys
provider "aws" {
  access_key = "pass_your_access_key"
  secret_key = "pass_your_secret_access_key"
  region     = "ap-south-1"
}
##Delete the below line for single availability zone
data "aws_availability_zones" "all" {}

resource "aws_instance" "madhav_application_server" {
  ami               = "${var.amis}"
  key_name               = "${var.key_name}"
  subnet_id              = "${aws_subnet.private_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.madhav_sg.id}"]
  source_dest_check = false
  instance_type = "t2.micro"
tags = {
    Name = "madhav_application_server"
  }
  
}
resource "aws_launch_configuration" "madhav_lt" {
  image_id               = "${var.amis}"
  instance_type          = "t2.micro"
  security_groups = ["${aws_security_group.madhav_sg.id}"]
  key_name               = "${var.key_name}"
  ebs_block_device {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "50"
      delete_on_termination = true
    }

  root_block_device {
      volume_size = "50"
      volume_type = "gp2"
    }
  user_data = <<-EOF
              #!/bin/bash
              yum -y update
              yum install -y httpd24
		echo "<h1>Yeahh, i am ready" | sudo tee  /var/www/html/index.html
              service httpd start
              pvcreate /dev/xvdz
              vgcreate vg_app /dev/xvdz
              lvcreate -L 50G -n lv_app vg_app
              mkfs.ext4 /dev/vg_app/lv_app
              echo "/dev/mapper/vg_app-lv_app /apps ext4 defaults   0   0"   >> /etc/fstab
              mkdir /apps
              mount -a
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "madhav_asg" {
  launch_configuration = "${aws_launch_configuration.madhav_lt.id}"
  vpc_zone_identifier = ["${aws_subnet.private_subnet.id}"]
  min_size = 2
  max_size = 4
  load_balancers = ["${aws_elb.madhav_lb.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "madhav-asg"
    propagate_at_launch = true
  }
}

resource "aws_elb" "madhav_lb" {
  name = "madhav-lb"
  security_groups = ["${aws_security_group.madhav_lb_sg.id}"]
  subnets            = ["${aws_subnet.public_subnet.id}"]
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:80/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "443"
    instance_protocol = "http"
  }
}
