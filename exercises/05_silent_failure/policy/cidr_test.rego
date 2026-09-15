package main

import rego.v1

ok := {"cidr": "10.1.0.0/16"}

ng := {"cidr": "192.168.0.0/16"}

test_allowed_passes if {
	count(deny) == 0 with input as ok # input=ok で deny 0 件
}

test_out_of_range_denied if {
	count(deny) == 1 with input as ng # input=ng で deny 1 件
}

test_missing_denied if {
	count(deny) == 1 with input as {} # cidr 無しでも deny 1 件
}
