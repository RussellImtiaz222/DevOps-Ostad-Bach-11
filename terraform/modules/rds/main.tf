# RDS Module - PostgreSQL Database
# KMS Key for RDS Encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS database encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-rds-key"
    }
  )
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.environment}-rds-encryption"
  target_key_id = aws_kms_key.rds.key_id
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-db-subnet-group"
    }
  )
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier            = "${var.environment}-database"
  engine                = var.engine
  engine_version        = var.engine_version
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn
  multi_az              = var.multi_az
  db_subnet_group_name  = aws_db_subnet_group.main.name
  db_name               = var.db_name
  username              = var.master_username
  password              = var.master_password
  parameter_group_name  = aws_db_parameter_group.main.name
  publicly_accessible   = false
  
  vpc_security_group_ids = [var.rds_security_group_id]
  
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  
  deletion_protection    = var.deletion_protection
  skip_final_snapshot    = var.skip_final_snapshot
  
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  iam_database_authentication_enabled = true

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-rds-postgresql"
    }
  )

  depends_on = [aws_db_subnet_group.main]
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres${var.engine_version}"
  name   = "${var.environment}-db-params"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_duration"
    value = "true"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "2000"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-db-parameter-group"
    }
  )
}

# CloudWatch Alarm - Database CPU (DISABLED - requires cloudwatch:PutMetricAlarm IAM permission)
# Use Prometheus + Grafana for equivalent monitoring
# resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
#   alarm_name          = "${var.environment}-rds-cpu-high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/RDS"
#   period              = "300"
#   statistic           = "Average"
#   threshold           = "80"
#
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# CloudWatch Alarm - Database Connections (DISABLED - requires cloudwatch:PutMetricAlarm IAM permission)
# Use Prometheus + Grafana for equivalent monitoring
# resource "aws_cloudwatch_metric_alarm" "rds_connections" {
#   alarm_name          = "${var.environment}-rds-connections-high"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "2"
#   metric_name         = "DatabaseConnections"
#   namespace           = "AWS/RDS"
#   period              = "300"
#   statistic           = "Average"
#   threshold           = "80"
#
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }

# CloudWatch Alarm - Free Storage Space (DISABLED - requires cloudwatch:PutMetricAlarm IAM permission)
# Use Prometheus + Grafana for equivalent monitoring
# resource "aws_cloudwatch_metric_alarm" "rds_storage" {
#   alarm_name          = "${var.environment}-rds-storage-low"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "FreeStorageSpace"
#   namespace           = "AWS/RDS"
#   period              = "300"
#   statistic           = "Average"
#   threshold           = "2147483648" # 2GB in bytes
#
#   dimensions = {
#     DBInstanceIdentifier = aws_db_instance.main.id
#   }
# }
