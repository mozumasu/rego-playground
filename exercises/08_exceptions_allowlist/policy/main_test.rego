package main

import rego.v1

# --- 採点用テスト。ここは編集しない ---

doc(path, name) := {"path": path, "contents": {"terraform": [{"cloud": [{
	"organization": "example-org",
	"workspaces": [{"name": name}],
}]}]}}

bad_env := doc("environments/production/web/terraform.tf", "app-staging-web")

bad_sep := doc("environments/staging/legacy/terraform.tf", "app_staging_legacy")

good := doc("environments/staging/web/terraform.tf", "app-staging-web")

# --- finding ---

test_env_mismatch_is_finding_with_rule if {
	fs := finding with input as [bad_env]
	count(fs) == 1
	some f in fs
	f.rule == "workspace_env_match"
	f.path == "environments/production/web/terraform.tf"
}

test_underscore_only_name_is_separator_finding if {
	fs := finding with input as [bad_sep]
	count(fs) == 1
	some f in fs
	f.rule == "workspace_separator"
}

test_hyphen_name_is_not_separator_finding if {
	count(finding) == 0 with input as [good]
}

test_mixed_separators_not_flagged if {
	# "-" を含んでいれば `_` 区切りとはみなさない (コンポーネント名内の "_" は可)
	count(finding) == 0 with input as [doc("environments/staging/web/terraform.tf", "app-staging-legacy_db")]
}

test_one_file_can_have_two_findings if {
	# env 不一致 かつ `_` 区切り
	count(finding) == 2 with input as [doc("environments/production/web/terraform.tf", "app_staging_web")]
}

# --- allowlist との突合 (deny) ---

test_no_allowlist_denies_everything if {
	count(deny) == 2 with input as [bad_env, bad_sep, good]
		with data.exceptions as []
}

test_file_level_exception_removes_only_that_finding if {
	count(deny) == 1 with input as [bad_env, bad_sep]
		with data.exceptions as [{
			"path": "environments/production/web/terraform.tf",
			"rule": "workspace_env_match",
			"reason": "移行中",
		}]
}

test_exception_is_scoped_to_rule if {
	# path は合っているが rule が違う → 免除されない
	count(deny) == 2 with input as [bad_env, bad_sep]
		with data.exceptions as [{
			"path": "environments/production/web/terraform.tf",
			"rule": "workspace_separator",
			"reason": "移行中",
		}]
}

test_wildcard_path_excepts_rule_repo_wide if {
	count(deny) == 1 with input as [bad_env, bad_sep]
		with data.exceptions as [{"path": "*", "rule": "workspace_separator", "reason": "規約制定前"}]
}

test_rule_typo_does_not_except if {
	count(deny) == 2 with input as [bad_env, bad_sep]
		with data.exceptions as [{
			"path": "environments/production/web/terraform.tf",
			"rule": "workspace_env_mach",
			"reason": "移行中",
		}]
}

test_empty_reason_is_invalid if {
	count(deny) == 2 with input as [bad_env, bad_sep]
		with data.exceptions as [{
			"path": "environments/production/web/terraform.tf",
			"rule": "workspace_env_match",
			"reason": "  ",
		}]
}

test_deny_carries_finding_message if {
	msgs := deny with input as [bad_sep] with data.exceptions as []
	"environments/staging/legacy/terraform.tf: workspace 名 \"app_staging_legacy\" は `_` 区切り。`-` を使うこと" in msgs
}
