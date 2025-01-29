data "aws_region" "current" {}

##########################
# IAMロールおよびプロファイル設定
##########################
# EC2がSession Managerを利用するためのIAMロールを作成
resource "aws_iam_role" "ssm_role" {
  name = "ec2_sample_ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Session Manager用のポリシーをIAMロールにアタッチ
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAMロールにSecrets Managerアクセス用のインラインポリシーを追加
resource "aws_iam_role_policy" "ssm_secrets_access" {
  name = "ssm-secrets-access"
  role = aws_iam_role.ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.aurora_password_a.arn
      }
    ]
  })
}

# IAMインスタンスプロファイルの作成
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2_sample_ssm_profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_security_group" "ec2_sg" {
  name        = "sample_ec2_sg"
  description = "A security group for EC2"
  vpc_id      = module.vpc_primary.vpc_id

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# EC2インスタンス設定(user_data は LF 改行で保存する)
resource "aws_instance" "ubuntu_ssm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.small"
  subnet_id                   = module.vpc_primary.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = false

  tags = {
    Name   = "Ubuntu-SSM"
    Backup = "Yes"
  }
}

# 最新のUbuntu 24.04 LTSのAMIを取得する例
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # CanonicalのAMI所有者ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}