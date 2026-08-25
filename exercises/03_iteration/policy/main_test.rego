package main

import rego.v1

# --- 採点用テスト。ここは編集しない ---

healthy := {"services": {
	"web": {"ports": [8080, 8443], "replicas": 3},
	"db": {"ports": [5432], "replicas": 2},
}}

test_healthy_no_deny if {
	count(deny) == 0 with input as healthy
}

test_privileged_port_denied if {
	deny["web: 特権ポート 80 は禁止"] with input as {"services": {
		"web": {"ports": [80, 8443], "replicas": 3},
		"db": {"ports": [5432], "replicas": 2},
	}}
}

test_multiple_privileged_ports_all_reported if {
	count(deny) == 2 with input as {"services": {
		"web": {"ports": [80, 443], "replicas": 3},
		"db": {"ports": [5432], "replicas": 2},
	}}
}

test_ha_ready_true if {
	ha_ready with input as healthy
}

test_single_replica_denied if {
	deny["全サービス replicas 2 以上が必要"] with input as {"services": {
		"web": {"ports": [8080], "replicas": 3},
		"db": {"ports": [5432], "replicas": 1},
	}}
}

test_boundary_two_replicas_ok if {
	count(deny) == 0 with input as {"services": {
		"web": {"ports": [8080], "replicas": 2},
		"db": {"ports": [5432], "replicas": 2},
	}}
}
