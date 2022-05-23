locals {
  setup_name = "kozo-ojt"
}

resource "aws_instance" "terraform-ec2" {
  ami = var.ami
  instance_type = var.instance_type

  # VPC
  subnet_id = "${aws_subnet.terraform-public-subnet-1.id}"

  # Security Group
  vpc_security_group_ids = [ "${aws_security_group.terraform-sg.id}" ]
  
  # The SSH key
  key_name = "kozo-ojt"

  # Apache2 installation
  user_data = "${data.template_file.user_data.rendered}"

  # Other configure instance
  hibernation = var.hibernation
  count = var.instance_count
  associate_public_ip_address = var.associate_public_ip_address
  monitoring = var.monitoring
  disable_api_termination = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  dynamic "root_block_device" {
    for_each = var.root_block_device

    content {
      volume_size = root_block_device.value.size
      encrypted = root_block_device.value.encrypted
    }
  }

  enclave_options {
    enabled = var.enclave_options_enabled
  }

  tags = {
    Name = "Demo EC2 with Terraform"
  }
}

resource "aws_vpc" "terraform-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_classiclink = var.enable_classiclink
  instance_tenancy = var.instance_tenancy

  tags = {
    Name = "${local.setup_name}-vpc"
  }
}

resource "aws_subnet" "terraform-public-subnet-1" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  cidr_block = "10.0.0.0/20"
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone = var.availability_zones[0]

  tags = {
    Name = "${local.setup_name}-public-subnet-1"
  }
}

resource "aws_subnet" "terraform-public-subnet-2" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  cidr_block = "10.0.16.0/20"
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "${local.setup_name}-public-subnet-2"
  }
}

resource "aws_internet_gateway" "terraform-igw" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
}

resource "aws_route_table" "terraform-public-crt" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.terraform-igw.id}"
  }
}

resource "aws_route_table_association" "terraform-crta-public-subnet-1" {
  subnet_id = "${aws_subnet.terraform-public-subnet-1.id}"
  route_table_id = "${aws_route_table.terraform-public-crt.id}"
}

resource "aws_security_group" "terraform-sg" {
  description = "Security group"
  vpc_id = "${aws_vpc.terraform-vpc.id}"

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      from_port = ingress.value.from_port
      to_port = ingress.value.to_port
      protocol = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules

    content {
      from_port = egress.value.from_port
      to_port = egress.value.to_port
      protocol = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
 
  tags = {
    Name = "${local.setup_name}-security-group"
  }
}

# resource block for ec2 and elastic ip association
resource "aws_eip" "terraform-eip" {
  vpc      = true
}

resource "aws_eip_association" "terraform-eip-assoc" {
  instance_id   = aws_instance.terraform-ec2[0].id
  allocation_id = aws_eip.terraform-eip.id
}

# Application load balancer security group
resource "aws_security_group" "terraform-alb-sg" {
  name        = "terraform-alb-security-group"
  description = "Terraform load balancer security group"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"

  dynamic "ingress" {
    for_each = var.alb_ingress_rules

    content {
      from_port = ingress.value.from_port
      to_port = ingress.value.to_port
      protocol = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.alb_egress_rules

    content {
      from_port = egress.value.from_port
      to_port = egress.value.to_port
      protocol = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

# Application load balancer
resource "aws_alb" "terraform-alb" {
  name            = "terraform-alb"
  security_groups = ["${aws_security_group.terraform-alb-sg.id}"]
  subnets         = ["${aws_subnet.terraform-public-subnet-1.id}", "${aws_subnet.terraform-public-subnet-2.id}"]
}

# Target group for the application load balancer
resource "aws_alb_target_group" "terraform-tg" {
  name     = "terraform-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.terraform-vpc.id}"
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/"
    port = 80
  }
}

resource "aws_lb_target_group_attachment" "terraform-tga" {
  count            = length(aws_instance.terraform-ec2)
  target_group_arn = aws_alb_target_group.terraform-tg.arn
  target_id        = aws_instance.terraform-ec2[0].id
  port             = 80
}

# Application load balancer listeners HTTP
resource "aws_alb_listener" "terraform-listener-http" {
  load_balancer_arn = "${aws_alb.terraform-alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Application load balancer listeners HTTPS
resource "aws_alb_listener" "terraform-listener-https" {
  load_balancer_arn = "${aws_alb.terraform-alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.certificate_arn}"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Server Unavailable"
      status_code  = "503"
    }
  }
}

resource "aws_lb_listener_rule" "terraform-listener-https-rule" {
  listener_arn = aws_alb_listener.terraform-listener-https.arn

  condition {
    host_header {
      values = ["terraform.kozo-ojt.developer07.tasdg.info"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.terraform-tg.arn
  }
}

# Route 53 for the load balancer
resource "aws_route53_record" "terraform-route53" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name    = "terraform.kozo-ojt.${var.route53_hosted_zone_name}"
  type    = "A"
  alias {
    name                   = "dualstack.${aws_alb.terraform-alb.dns_name}"
    zone_id                = "${aws_alb.terraform-alb.zone_id}"
    evaluate_target_health = true
  }
}