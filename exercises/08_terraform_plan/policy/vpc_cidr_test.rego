package main

import rego.v1

# --- 採点用テスト。ここは編集しない ---

vpc_plan(cidr) := {"resource_changes": [{
	"address": "module.network.aws_vpc.this",
	"type": "aws_vpc",
	"mode": "managed",
	"change": {
		"actions": ["create"],
		"after": {"cidr_block": cidr},
	},
}]}

test_production_range_allowed if {
	count(deny) == 0 with input as vpc_plan("10.0.0.0/16")
}

test_staging_range_allowed if {
	count(deny) == 0 with input as vpc_plan("172.31.0.0/16")
}

test_out_of_range_denied if {
	count(deny) == 1 with input as vpc_plan("192.168.0.0/16")
}

test_wrong_prefix_denied if {
	count(deny) == 1 with input as vpc_plan("10.0.0.0/24")
}

test_delete_not_denied if {
	count(deny) == 0 with input as {"resource_changes": [{
		"address": "module.network.aws_vpc.this",
		"type": "aws_vpc",
		"mode": "managed",
		"change": {"actions": ["delete"], "after": null},
	}]}
}

test_replace_out_of_range_denied if {
	count(deny) == 1 with input as {"resource_changes": [{
		"address": "module.network.aws_vpc.this",
		"type": "aws_vpc",
		"mode": "managed",
		"change": {
			"actions": ["delete", "create"],
			"after": {"cidr_block": "192.168.0.0/16"},
		},
	}]}
}

test_non_vpc_ignored if {
	count(deny) == 0 with input as {"resource_changes": [{
		"address": "module.network.aws_subnet.a",
		"type": "aws_subnet",
		"mode": "managed",
		"change": {
			"actions": ["create"],
			"after": {"cidr_block": "192.168.1.0/24"},
		},
	}]}
}

# ここが negation の罠の検証: 素朴な not is_string(...) 実装だとこの 2 つが落ちる
test_unknown_cidr_denied_fail_closed if {
	count(deny) == 1 with input as {"resource_changes": [{
		"address": "module.network.aws_vpc.this",
		"type": "aws_vpc",
		"mode": "managed",
		"change": {
			"actions": ["create"],
			"after": {},
			"after_unknown": {"cidr_block": true},
		},
	}]}
}

test_null_cidr_denied_fail_closed if {
	count(deny) == 1 with input as {"resource_changes": [{
		"address": "module.network.aws_vpc.this",
		"type": "aws_vpc",
		"mode": "managed",
		"change": {
			"actions": ["create"],
			"after": {"cidr_block": null},
		},
	}]}
}
