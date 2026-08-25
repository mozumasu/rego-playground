package main

import rego.v1

# --- 採点用テスト。ここは編集しない ---

test_prefix_length if {
	prefix_length("10.0.0.0/16") == 16
	prefix_length("192.168.1.0/24") == 24
}

test_production_range_allowed if {
	cidr_allowed("10.0.0.0/16")
	cidr_allowed("10.15.0.0/16")
}

test_staging_range_allowed if {
	cidr_allowed("172.16.0.0/16")
	cidr_allowed("172.31.0.0/16")
}

test_out_of_range_not_allowed if {
	not cidr_allowed("192.168.0.0/16")
	not cidr_allowed("10.16.0.0/16")
	not cidr_allowed("172.32.0.0/16")
}

test_wrong_prefix_not_allowed if {
	not cidr_allowed("10.0.0.0/24")
	not cidr_allowed("10.0.0.0/12")
}

test_valid_vpc_no_deny if {
	count(deny) == 0 with input as {"vpc_cidr": "10.3.0.0/16"}
}

test_invalid_vpc_denied if {
	deny["VPC CIDR 192.168.0.0/16 は割当標準外"] with input as {"vpc_cidr": "192.168.0.0/16"}
}
