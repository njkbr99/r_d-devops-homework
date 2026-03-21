# RDS subnet group — spans both private subnets across 2 AZs (required by AWS)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name    = "${var.project}-db-subnet-group"
    Project = var.project
  }
}

# RDS MySQL instance
resource "aws_db_instance" "mysql" {
  identifier        = "${var.project}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  allocated_storage     = 20
  storage_type          = "gp3"
  publicly_accessible   = false
  multi_az              = false
  skip_final_snapshot   = true
  deletion_protection   = false

  tags = {
    Name    = "${var.project}-mysql"
    Project = var.project
  }
}
