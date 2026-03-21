# App EC2 security group
resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "App EC2 - SSH from your IP, port 3000 public, Node Exporter from monitoring only"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${local.name_prefix}-app-sg"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_security_group_rule" "app_ssh" {
  type              = "ingress"
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.your_ip]
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_ssh_cicd" {
  type              = "ingress"
  description       = "SSH from GitHub Actions"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_api" {
  type                     = "ingress"
  description              = "App API from ALB only"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "app_metrics" {
  type                     = "ingress"
  description              = "Prometheus metrics scrape from monitoring"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.monitoring.id
}

# ALB security group — accepts HTTP from anywhere, forwards to app EC2
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB - HTTP from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${local.name_prefix}-alb-sg"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_security_group_rule" "app_node_exporter" {
  type                     = "ingress"
  description              = "Node Exporter metrics"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.monitoring.id
}

# Monitoring EC2 security group
resource "aws_security_group" "monitoring" {
  name        = "${local.name_prefix}-monitoring-sg"
  description = "Monitoring EC2 - SSH, Grafana, Prometheus from your IP; Loki from app only"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${local.name_prefix}-monitoring-sg"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_security_group_rule" "monitoring_ssh" {
  type              = "ingress"
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.your_ip]
  security_group_id = aws_security_group.monitoring.id
}

resource "aws_security_group_rule" "monitoring_grafana" {
  type              = "ingress"
  description       = "Grafana"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = [var.your_ip]
  security_group_id = aws_security_group.monitoring.id
}

resource "aws_security_group_rule" "monitoring_prometheus" {
  type              = "ingress"
  description       = "Prometheus"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = [var.your_ip]
  security_group_id = aws_security_group.monitoring.id
}

resource "aws_security_group_rule" "monitoring_loki" {
  type                     = "ingress"
  description              = "Loki log ingestion"
  from_port                = 3100
  to_port                  = 3100
  protocol                 = "tcp"
  security_group_id        = aws_security_group.monitoring.id
  source_security_group_id = aws_security_group.app.id
}

# RDS security group
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "RDS MySQL - port 3306 from app EC2 only, no public access"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${local.name_prefix}-rds-sg"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_security_group_rule" "rds_mysql" {
  type                     = "ingress"
  description              = "MySQL from app"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.app.id
}
