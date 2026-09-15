package main

import rego.v1

allowed := {"10.0.0.0/12", "172.16.0.0/12"}

# ヘルパー関数 (自作): 名前(引数) if { ... }
cidr_allowed(cidr) if {
	is_string(cidr)   # null や数値は組み込み関数に渡す前に弾く
	some range in allowed
	net.cidr_contains(range, cidr)
	# "10.0.0.0/16" → split → ["10.0.0.0", "16"] → [1] → "16" → 16
	to_number(split(cidr, "/")[1]) == 16
}

deny contains msg if {
	cidr := object.get(input, ["cidr"], null)   # cidr が無くても null にして、下の not に届かせる
	not cidr_allowed(cidr)
	msg := sprintf("CIDR %v は割当外です", [cidr])
}
