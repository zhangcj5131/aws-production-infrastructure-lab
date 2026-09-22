resource "aws_db_subnet_group" "v4" {
  name        = "v4-db-subnet-group"
  description = "Private DB subnet group for V4 RDS Multi-AZ"

  subnet_ids = [
    aws_subnet.private_data_a3.id,
    aws_subnet.private_data_b3.id
  ]
}

resource "aws_db_instance" "v4" {
  identifier = "v4-web-db"

  engine         = "mysql"
  engine_version = "8.4.9"
  instance_class = "db.t4g.micro"

  db_name  = "appdb"
  username = "admin"

  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.v4.arn

  allocated_storage     = 20
  max_allocated_storage = 1000
  storage_type          = "gp3"


  storage_encrypted = true
  kms_key_id        = aws_kms_key.v4.arn

  multi_az            = true
  publicly_accessible = false

  db_subnet_group_name = aws_db_subnet_group.v4.name

  vpc_security_group_ids = [
    aws_security_group.db.id
  ]

  iam_database_authentication_enabled = false

  backup_retention_period = 1
  backup_window           = "03:22-03:52"
  copy_tags_to_snapshot   = true

  auto_minor_version_upgrade = true

  deletion_protection = false

  monitoring_interval = 0

  skip_final_snapshot = true

  tags = {
    Environment = "lab"
    Project     = "aws-prod-lab-v4"
  }
}