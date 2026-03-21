# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${local.name_prefix}-vpc"
    Project = var.project
    Owner   = var.owner
  }
}

# Public subnets (EC2 instances live here)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.2.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "${local.name_prefix}-public-a"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.2.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "${local.name_prefix}-public-b"
    Project = var.project
    Owner   = var.owner
  }
}

# Private subnets (RDS lives here — not reachable from internet)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.3.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name    = "${local.name_prefix}-private-a"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.4.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name    = "${local.name_prefix}-private-b"
    Project = var.project
    Owner   = var.owner
  }
}

# Internet Gateway — connects the VPC to the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${local.name_prefix}-igw"
    Project = var.project
    Owner   = var.owner
  }
}

# Route table for public subnets — sends internet traffic through IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${local.name_prefix}-public-rt"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for monitoring EC2 — keeps Grafana URL stable across restarts
resource "aws_eip" "monitoring" {
  domain = "vpc"

  tags = {
    Name    = "${local.name_prefix}-monitoring-eip"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_eip_association" "monitoring" {
  instance_id   = aws_instance.monitoring.id
  allocation_id = aws_eip.monitoring.id
}

# Application Load Balancer — stable entry point for the app
resource "aws_lb" "app" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name    = "${local.name_prefix}-alb"
    Project = var.project
    Owner   = var.owner
  }
}

# Target group — tells the ALB to forward traffic to the app EC2 on port 3000
resource "aws_lb_target_group" "app" {
  name     = "${var.project}-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = {
    Name    = "${local.name_prefix}-tg"
    Project = var.project
    Owner   = var.owner
  }
}

# Register the app EC2 instance into the target group
resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 3000
}

# Listener — ALB accepts HTTP on port 80 and forwards to the target group
resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}