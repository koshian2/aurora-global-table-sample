# Aurora Global Clusterの作成
resource "aws_rds_global_cluster" "aurora_global_cluster" {
  global_cluster_identifier = "my-aurora-global-cluster"
  engine                    = "aurora-postgresql"
  engine_version            = "16.6" # 利用可能な最新バージョンに合わせる
  storage_encrypted         = true
}

# リージョンAのDB Subnet Group
resource "aws_db_subnet_group" "aurora_subnet_group_a" {
  name        = "aurora-subnet-group-a"
  subnet_ids  = module.vpc_primary.private_subnet_ids
  description = "Subnet group for Aurora in Region A"
}

# Auroraのマスターパスワードの生成と保存
resource "random_password" "aurora_password_a" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "aurora_password_a" {
  name                    = "aurora-master-password-a"
  description             = "Master password for Aurora PostgreSQL in Region A stored in Secrets Manager"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "aurora_password_version_a" {
  secret_id     = aws_secretsmanager_secret.aurora_password_a.id
  secret_string = random_password.aurora_password_a.result
}

locals {
  all_private_subnets = [
    var.primary_vpc_cidr_block,
    var.secondary_vpc_cidr_block_b,
    var.secondary_vpc_cidr_block_c
  ]
}

# リージョンAのセキュリティグループ
resource "aws_security_group" "aurora_sg_a" {
  name        = "aurora-postgres-sg-a"
  description = "Allow inbound PostgreSQL traffic in Region A"
  vpc_id      = module.vpc_primary.vpc_id

  ingress {
    description = "PostgreSQL port"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.all_private_subnets
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# リージョンAのAuroraクラスター（プライマリ）
resource "aws_rds_cluster" "primary_cluster" {
  provider             = aws
  cluster_identifier   = "my-aurora-primary-cluster"
  engine               = "aurora-postgresql"
  engine_version       = "16.6"
  master_username      = "postgres"
  master_password      = aws_secretsmanager_secret_version.aurora_password_version_a.secret_string
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group_a.name

  # Aurora Serverless v2 のスケーリング設定
  serverlessv2_scaling_configuration {
    min_capacity             = 0.0 # 必要に応じて変更
    max_capacity             = 1.0 # 必要に応じて変更
    seconds_until_auto_pause = 300
  }

  vpc_security_group_ids = [
    aws_security_group.aurora_sg_a.id
  ]

  storage_encrypted   = true
  deletion_protection = false
  skip_final_snapshot = true

  global_cluster_identifier = aws_rds_global_cluster.aurora_global_cluster.global_cluster_identifier
}

# プライマリインスタンス
resource "aws_rds_cluster_instance" "primary_instance" {
  provider             = aws
  identifier           = "my-aurora-primary-instance"
  cluster_identifier   = aws_rds_cluster.primary_cluster.id
  engine               = aws_rds_cluster.primary_cluster.engine
  instance_class       = "db.serverless"
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group_a.name
  promotion_tier       = 1
}

# リージョンA内のリードレプリカ
resource "aws_rds_cluster_instance" "read_replica_a" {
  provider             = aws
  identifier           = "my-aurora-read-replica-a"
  cluster_identifier   = aws_rds_cluster.primary_cluster.id
  engine               = aws_rds_cluster.primary_cluster.engine
  instance_class       = "db.serverless"
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group_a.name
  promotion_tier       = 2
  # ライターインスタンスを作ってからリードレプリカを作成
  depends_on = [aws_rds_cluster_instance.primary_instance]
}
