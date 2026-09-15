package main

import rego.v1

allowed_ranges := {"10.0.0.0/12", "172.16.0.0/12"}

# TODO(1): "10.0.0.0/16" → 16 を返すように書き換える
prefix_length(_) := -1

# TODO(2): /16 かつ allowed_ranges のいずれかに含まれるとき true になるように書き換える
cidr_allowed(_) if {
	false # 仮実装。正しく実装する
}

# TODO(3): input.vpc_cidr が cidr_allowed でなければ deny
# msg は sprintf("VPC CIDR %s は割当標準外", [input.vpc_cidr])
deny contains msg if {
	false # ここを実装する (この行は消す)
	msg := "TODO"
}
