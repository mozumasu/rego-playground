package main

import rego.v1

# --- 採点用テスト。ここは編集しない ---

test_production_debug_denied if {
	deny["production で debug は有効にできない"] with input as {
		"environment": "production",
		"debug": true,
		"replicas": 3,
	}
}

test_staging_debug_allowed if {
	count(deny) == 0 with input as {
		"environment": "staging",
		"debug": true,
		"replicas": 3,
	}
}

test_production_without_debug_allowed if {
	count(deny) == 0 with input as {
		"environment": "production",
		"debug": false,
		"replicas": 3,
	}
}

test_zero_replicas_denied if {
	deny["replicas は 1 以上が必要"] with input as {
		"environment": "staging",
		"debug": false,
		"replicas": 0,
	}
}

test_one_replica_allowed if {
	count(deny) == 0 with input as {
		"environment": "staging",
		"debug": false,
		"replicas": 1,
	}
}

test_both_violations_denied if {
	count(deny) == 2 with input as {
		"environment": "production",
		"debug": true,
		"replicas": 0,
	}
}
