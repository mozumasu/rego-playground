package hcl

import rego.v1

# environments/<env>/... の <env> を取る
path_env(path) := parts[i + 1] if {
	parts := split(path, "/")    # "/" で切って配列に
	some i                      # 添字 i を全部試す
	parts[i] == "environments"  # environments が i 番目
}                               # 返り値は parts[i + 1]

# --combine した input は [{path, contents}] の配列。ブロックは 1 個でも配列になる
deny contains msg if {
	some f in input
	env := path_env(f.path)
	tf := f.contents.terraform[_]
	some ws in tf.cloud[_].workspaces
	segs := regex.split(`[-_]`, ws.name)
	not env in segs
	msg := sprintf("%s: workspace 名 %q に %q が無い", [f.path, ws.name, env])
}
