package main

import rego.v1

# スライド「plan JSON はどんな形か」の deny。見るのは resource_changes だけ
deny contains msg if {
	some rc in input.resource_changes
	rc.type == "aws_vpc"
	"create" in rc.change.actions
	cidr := rc.change.after.cidr_block
	not net.cidr_contains("10.0.0.0/12", cidr)
	msg := sprintf("%s: CIDR %s は割当外", [rc.address, cidr])
}

# fail-closed: plan 時に CIDR が確定していない (after に無く after_unknown に入る) VPC も deny する。
# not の中に rc.change.after.cidr_block を直接書くと、キーが無い時点でルールごと消えて通ってしまう
deny contains msg if {
	some rc in input.resource_changes
	rc.type == "aws_vpc"
	"create" in rc.change.actions
	cidr := object.get(rc.change, ["after", "cidr_block"], null)
	not is_string(cidr)
	msg := sprintf("%s: plan 時に CIDR が確定していない", [rc.address])
}
