package main

import rego.v1

# 各テストの false の行を、with input as を使った本物の検証に書き換える

# 正常系: バージョン固定タグ + cpu_limit 上限内なら deny なし
test_pinned_image_within_limit_ok if {
	false # TODO
}

# 異常系: :latest タグは deny される
test_latest_tag_denied if {
	false # TODO
}

# 異常系: cpu_limit 超過は deny される
test_cpu_over_limit_denied if {
	false # TODO
}

# 境界値: cpu_limit がちょうど 4 なら deny されない
test_cpu_exactly_at_limit_ok if {
	false # TODO
}

# 境界値: cpu_limit が 5 なら deny される
test_cpu_just_over_limit_denied if {
	false # TODO
}

# 相反検証: "latest" を含むが :latest タグではない image は deny されない
# (例: "myapp:latest-fix-123" ではなく "registry/latest-app:v1.2.3" のような名前)
test_latest_in_name_but_pinned_ok if {
	false # TODO
}

# 複合: 両方違反なら deny は 2 件
test_both_violations_counted if {
	false # TODO
}
