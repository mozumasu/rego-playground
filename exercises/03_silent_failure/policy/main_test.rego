package main

import rego.v1

# --- 採点用テスト。ここは編集しない ---

config(overrides) := object.union(
	{
		"name": "web-01",
		"port": 443,
		"tls": {"enabled": true},
		"tags": ["prod"],
	},
	overrides,
)

# 誤爆しないこと: 準拠した構成は pass
test_clean_config_not_denied if {
	count(deny) == 0 with input as config({})
}

# バグ 1 (tls.rego): TLS 無効を検出できていない
test_tls_disabled_denied if {
	deny["TLS が無効です。tls.enabled を true にしてください"] with input as config({"tls": {"enabled": false}})
}

# バグ 2 (port.rego): 許可外ポートを検出できていない
test_port_not_allowed_denied if {
	deny["ポート 8080 は許可されていません。443 を使ってください"] with input as config({"port": 8080})
}

# バグ 3 (tags.rego): deprecated タグを検出できていない
test_deprecated_tag_denied if {
	deny["deprecated タグが付いています。タグを外してください"] with input as config({"tags": ["prod", "deprecated"]})
}

# 3 つ同時に違反していれば 3 件
test_all_violations_denied if {
	count(deny) == 3 with input as config({
		"port": 8080,
		"tls": {"enabled": false},
		"tags": ["prod", "deprecated"],
	})
}
