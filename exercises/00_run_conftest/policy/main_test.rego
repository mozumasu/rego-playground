package main

import rego.v1

test_debug_on_production_denied if {
	count(deny) == 1 with input as {"environment": "production", "debug": true}
}

test_debug_off_passes if {
	count(deny) == 0 with input as {"environment": "production", "debug": false}
}
