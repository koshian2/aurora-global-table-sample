data "aws_caller_identity" "current" {}

data "aws_region" "region_b" {
  provider = aws.secondary_b
}

data "aws_region" "region_c" {
  provider = aws.secondary_c
}

# リージョンBのDB Subnet Group
resource "aws_db_subnet_group" "aurora_subnet_group_b" {
  provider    = aws.secondary_b
  name        = "aurora-subnet-group-b"
  subnet_ids  = module.vpc_secondary_b.private_subnet_ids
  description = "Subnet group for Aurora in Region B"
}

# リージョンBのセキュリティグループ
resource "aws_security_group" "aurora_sg_b" {
  provider    = aws.secondary_b
  name        = "aurora-postgres-sg-b"
  description = "Allow inbound PostgreSQL traffic in Region B"
  vpc_id      = module.vpc_secondary_b.vpc_id

  ingress {
    description = "PostgreSQL port"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.all_private_subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# リージョンBのAuroraクラスター（クロスリージョンリードレプリカ）
resource "aws_rds_cluster" "cross_region_replica_b" {
  provider             = aws.secondary_b
  cluster_identifier   = "my-aurora-cross-replica-b"
  engine               = "aurora-postgresql"
  engine_version       = "16.6"
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group_b.name
  kms_key_id           = "arn:aws:kms:${data.aws_region.region_b.name}:${data.aws_caller_identity.current.account_id}:alias/aws/rds" 

  # Aurora Serverless v2 のスケーリング設定
  serverlessv2_scaling_configuration {
    min_capacity             = 0.0 # 必要に応じて変更
    max_capacity             = 1.0 # 必要に応じて変更
    seconds_until_auto_pause = 300
  }

  vpc_security_group_ids = [
    aws_security_group.aurora_sg_b.id
  ]

  storage_encrypted   = true
  deletion_protection = false
  skip_final_snapshot = true

  global_cluster_identifier = aws_rds_global_cluster.aurora_global_cluster.global_cluster_identifier
}

# リージョンBのAuroraリードレプリカインスタンス
resource "aws_rds_cluster_instance" "cross_region_instance_b" {
  provider             = aws.secondary_b
  identifier           = "my-aurora-cross-instance-b"
  cluster_identifier   = aws_rds_cluster.cross_region_replica_b.id
  engine               = aws_rds_cluster.cross_region_replica_b.engine
  instance_class       = "db.serverless"
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group_b.name

  depends_on = [aws_rds_cluster.cross_region_replica_b]
}

# リージョンCのDB Subnet Group
resource "aws_db_subnet_group" "aurora_subnet_group_c" {
  provider    = aws.secondary_c
  name        = "aurora-subnet-group-c"
  subnet_ids  = module.vpc_secondary_c.private_subnet_ids
  description = "Subnet group for Aurora in Region C"
}

# リージョンCのセキュリティグループ
resource "aws_security_group" "aurora_sg_c" {
  provider    = aws.secondary_c
  name        = "aurora-postgres-sg-c"
  description = "Allow inbound PostgreSQL traffic in Region C"
  vpc_id      = module.vpc_secondary_c.vpc_id

  ingress {
    description = "PostgreSQL port"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.all_private_subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# リージョンCのAuroraクラスター（クロスリージョンリードレプリカ）
resource "aws_rds_cluster" "cross_region_replica_c" {
  provider             = aws.secondary_c
  cluster_identifier   = "my-aurora-cross-replica-c"
  engine               = "aurora-postgresql"
  engine_version       = "16.6"
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group_c.name
  kms_key_id           = "arn:aws:kms:${data.aws_region.region_c.name}:${data.aws_caller_identity.current.account_id}:alias/aws/rds" 

  # Aurora Serverless v2 のスケーリング設定
  serverlessv2_scaling_configuration {
    min_capacity             = 0.0 # 必要に応じて変更
    max_capacity             = 1.0 # 必要に応じて変更
    seconds_until_auto_pause = 300
  }
  
  vpc_security_group_ids = [
    aws_security_group.aurora_sg_c.id
  ]

  storage_encrypted   = true
  deletion_protection = false
  skip_final_snapshot = true

  global_cluster_identifier = aws_rds_global_cluster.aurora_global_cluster.global_cluster_identifier
}

# リージョンCのAuroraリードレプリカインスタンス
resource "aws_rds_cluster_instance" "cross_region_instance_c" {
  provider             = aws.secondary_c
  identifier           = "my-aurora-cross-instance-c"
  cluster_identifier   = aws_rds_cluster.cross_region_replica_c.id
  engine               = aws_rds_cluster.cross_region_replica_c.engine
  instance_class       = "db.serverless"
  db_subnet_group_name = aws_db_subnet_group.aurora_subnet_group_c.name
  depends_on           = [aws_rds_cluster.cross_region_replica_c]
}
