package main

import rego.v1

# --- 採点用テスト。ここは編集しない ---

ok := {"tags": {"env": "prod", "owner": "sre-team"}}

test_env_dev_denied if {
	deny["env が prod ではない"] with input as {"tags": {"env": "dev", "owner": "sre-team"}}
}

test_env_prod_passes if {
	count(deny) == 0 with input as ok
}

# キー欠落は fail-closed: tags が無くても deny が出ること (!= のままだとここが落ちる)
test_missing_tags_denied if {
	deny["env が prod ではない"] with input as {}
}

test_missing_owner_denied if {
	deny["owner は必須"] with input as {"tags": {"env": "prod"}}
}

test_empty_owner_denied if {
	deny["owner は必須"] with input as {"tags": {"env": "prod", "owner": ""}}
}

test_owner_present_passes if {
	not deny["owner は必須"] with input as ok
}
