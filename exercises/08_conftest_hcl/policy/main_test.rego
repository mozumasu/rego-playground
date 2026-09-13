package main

import rego.v1

# --- 採点用テスト。ここは編集しない ---

# --combine した input の 1 要素を組み立てる
doc(path, name) := {"path": path, "contents": {"terraform": [{"cloud": [{
	"organization": "example-org",
	"workspaces": [{"name": name}],
}]}]}}

no_cloud(path) := {"path": path, "contents": {"resource": [{"aws_vpc": [{"this": [{"cidr_block": "10.0.0.0/16"}]}]}]}}

# --- helpers ---

test_workspace_name_extracts_name if {
	workspace_name(doc("environments/staging/web/terraform.tf", "app-staging-web")) == "app-staging-web"
}

test_workspace_name_undefined_without_cloud_block if {
	not workspace_name(no_cloud("environments/staging/web/main.tf"))
}

test_path_env_takes_segment_after_environments if {
	path_env("environments/production/web/terraform.tf") == "production"
}

test_path_env_works_with_prefix if {
	path_env("terraform/environments/staging/api/terraform.tf") == "staging"
}

test_path_env_undefined_without_environments if {
	not path_env("modules/vpc/main.tf")
}

test_segments_split_on_hyphen_and_underscore if {
	segments("app-staging_web") == {"app", "staging", "web"}
}

# --- deny ---

test_env_in_name_passes if {
	count(deny) == 0 with input as [doc("environments/staging/web/terraform.tf", "app-staging-web")]
}

test_env_mismatch_denied if {
	count(deny) == 1 with input as [doc("environments/production/web/terraform.tf", "app-staging-web")]
}

test_underscore_separator_accepted if {
	count(deny) == 0 with input as [doc("environments/production/api/terraform.tf", "app_production_api")]
}

test_partial_match_is_not_enough if {
	# "prod" は "production" ではない
	count(deny) == 1 with input as [doc("environments/production/web/terraform.tf", "app-prod-web")]
}

test_file_without_cloud_block_ignored if {
	count(deny) == 0 with input as [no_cloud("environments/staging/web/main.tf")]
}

test_path_without_environments_ignored if {
	count(deny) == 0 with input as [doc("modules/shared/terraform.tf", "app-staging-web")]
}

test_each_violation_reported if {
	count(deny) == 2 with input as [
		doc("environments/production/web/terraform.tf", "app-staging-web"),
		doc("environments/staging/api/terraform.tf", "app-production-api"),
		doc("environments/staging/web/terraform.tf", "app-staging-web"),
	]
}

test_deny_message_names_file_and_env if {
	msgs := deny with input as [doc("environments/production/web/terraform.tf", "app-staging-web")]
	"environments/production/web/terraform.tf: workspace 名 \"app-staging-web\" に env \"production\" が含まれていない" in msgs
}
