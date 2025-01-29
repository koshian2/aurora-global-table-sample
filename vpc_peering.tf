# --------------------------------------------------------------------------------
# VPC A → VPC B 用
# --------------------------------------------------------------------------------
# 1. A 側から Peering 接続を作成（auto_accept を false に）
resource "aws_vpc_peering_connection" "a_to_b" {
  # Primary (ap-northeast-1) リージョンのデフォルトプロバイダ
  provider    = aws
  vpc_id      = module.vpc_primary.vpc_id
  peer_vpc_id = module.vpc_secondary_b.vpc_id
  peer_region = "us-east-1" # VPC B が属するリージョン
  auto_accept = false       # ここがtrueにはできない
  tags = {
    Name = "a-to-b-peering"
  }
}

# 2. B 側で Peering 接続を承認
resource "aws_vpc_peering_connection_accepter" "b_accept_a" {
  # Secondary B 用プロバイダ (us-east-1)
  provider                  = aws.secondary_b
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id
  auto_accept               = true
  tags = {
    Name = "b-accept-a"
  }
}

# 3. 各 VPC のルートテーブルにルートを追加
## A 側の Private Route Table から B へのルート
resource "aws_route" "route_a_to_b" {
  provider                  = aws
  route_table_id            = module.vpc_primary.private_route_table_id
  destination_cidr_block    = module.vpc_secondary_b.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_b.id
}

## B 側の Private Route Table から A へのルート
resource "aws_route" "route_b_to_a" {
  provider               = aws.secondary_b
  route_table_id         = module.vpc_secondary_b.private_route_table_id
  destination_cidr_block = module.vpc_primary.vpc_cidr_block
  # accepter 側リソースの ID を使うのが一般的だが vpc_peering_connection 本体でも可
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.b_accept_a.id
}

# --------------------------------------------------------------------------------
# VPC A → VPC C 用
# --------------------------------------------------------------------------------
# 1. A 側から Peering 接続を作成（auto_accept を false に）
resource "aws_vpc_peering_connection" "a_to_c" {
  # Primary (ap-northeast-1) リージョンのデフォルトプロバイダ
  provider    = aws
  vpc_id      = module.vpc_primary.vpc_id
  peer_vpc_id = module.vpc_secondary_c.vpc_id
  peer_region = "us-west-2" # VPC C が属するリージョン
  auto_accept = false
  tags = {
    Name = "a-to-c-peering"
  }
}

# 2. C 側で Peering 接続を承認
resource "aws_vpc_peering_connection_accepter" "c_accept_a" {
  # Secondary C 用プロバイダ (us-west-1)
  provider                  = aws.secondary_c
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_c.id
  auto_accept               = true
  tags = {
    Name = "c-accept-a"
  }
}

# 3. 各 VPC のルートテーブルにルートを追加
## A 側の Private Route Table から C へのルート
resource "aws_route" "route_a_to_c" {
  provider                  = aws
  route_table_id            = module.vpc_primary.private_route_table_id
  destination_cidr_block    = module.vpc_secondary_c.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.a_to_c.id
}

## C 側の Private Route Table から A へのルート
resource "aws_route" "route_c_to_a" {
  provider                  = aws.secondary_c
  route_table_id            = module.vpc_secondary_c.private_route_table_id
  destination_cidr_block    = module.vpc_primary.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.c_accept_a.id
}
