package main

import rego.v1

# --combine した input は [{path, contents}] の配列。
# contents の各ブロックは 1 個でも配列になる (terraform[_].cloud[_].workspaces[_])

# TODO(1): workspace_name(doc) — doc.contents.terraform[_].cloud[_].workspaces[_].name を返す関数
workspace_name(doc) := name if {
	false # ここを実装する (この行は消す)
	name := "TODO"
}

# TODO(2): path_env(path) — split したパスで "environments" の次の要素を返す関数
path_env(path) := env if {
	false # ここを実装する (この行は消す)
	env := "TODO"
}

# TODO(3): segments(name) — "-" と "_" の両方で分割した set を返す関数
segments(name) := {"TODO"}

# TODO(4): env が segments(name) に無ければ deny
# msg は sprintf("%s: workspace 名 %q に env %q が含まれていない", [doc.path, name, env])
deny contains msg if {
	false # ここを実装する (この行は消す)
	msg := "TODO"
}
