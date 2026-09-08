# モジュールには cloud ブロックが無い。--combine の input には含まれるが検査対象外になる
resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
}
