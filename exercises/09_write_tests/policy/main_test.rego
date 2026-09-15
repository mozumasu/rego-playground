package hcl

import rego.v1

# --combine の input を手で組む。ポリシーが参照するキーだけ再現すればよい
tf(path, name) := [{"path": path, "contents": {"terraform": [{"cloud": [{"workspaces": [{"name": name}]}]}]}}]

ok := tf("environments/staging/a.tf", "myapp-staging")

ng := tf("environments/staging/a.tf", "myapp-prod")

# 1. 準拠入力が pass — 正しいものを止めていない
test_env_match_passes if {
	count(deny) == 0 with input as ok
}

# 2. 違反入力が deny — ポリシーが生きている
test_env_mismatch_denied if {
	count(deny) == 1 with input as ng
}

# 3. 欠落入力 — environments/ の外のファイルは対象外なので deny 0 件
test_outside_environments_ignored if {
	count(deny) == 0 with input as tf("modules/vpc/main.tf", "whatever")
}

# finding 方式ならさらに 2 点を固定する

# rule 識別子そのもの。タイポは「免除されないだけ」で気付けない
test_rule_id if {
	{v.rule | some v in finding} == {"workspace_env_match"}
		with input as ng
}

# allowlist に載せたら deny が消える
test_excepted if {
	ex := [{"path": "environments/staging/a.tf",
	        "rule": "workspace_env_match", "reason": "旧名を維持"}]
	count(deny) == 0 with input as ng with data.exceptions as ex
}

# reason が空なら免除されない
test_empty_reason_not_excepted if {
	ex := [{"path": "environments/staging/a.tf", "rule": "workspace_env_match", "reason": ""}]
	count(deny) == 1 with input as ng with data.exceptions as ex
}
