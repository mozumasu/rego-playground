package main

import rego.v1

allowed_ranges := {"10.0.0.0/12", "172.16.0.0/12"}

# TODO(1): vpc_creations — create される aws_vpc (managed) を集める set ルール

# TODO(2): cidr_allowed(cidr) — /16 かつ allowed_ranges のいずれかに含まれる

# TODO(3): 割当標準外の CIDR を deny
# msg は sprintf("%s: VPC CIDR %q は割当標準外", [rc.address, cidr])
deny contains msg if {
	false # ここを実装する (この行は消す)
	msg := "TODO"
}

# TODO(4): fail-closed — cidr_block が未確定/欠落なら deny (object.get を使うこと)
# msg は sprintf("%s: plan 時に VPC CIDR が確定していない", [rc.address])
deny contains msg if {
	false # ここを実装する (この行は消す)
	msg := "TODO"
}
