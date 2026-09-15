package hcl

import rego.v1

# environments/<env>/... の <env> を取る
path_env(path) := parts[i + 1] if {
	parts := split(path, "/")
	some i
	parts[i] == "environments"
}

# ルールは deny を書かず finding {path, rule, msg} を出すだけ。
# 免除の判定は exceptions.rego の 1 箇所に集める

finding contains v if {
	some f in input
	env := path_env(f.path)
	tf := f.contents.terraform[_]
	some ws in tf.cloud[_].workspaces
	segs := regex.split(`[-_]`, ws.name)
	not env in segs
	v := {
		"path": f.path,
		"rule": "workspace_env_match",
		"msg": sprintf("%s: workspace 名 %q に %q が無い", [f.path, ws.name, env]),
	}
}

finding contains v if {
	some f in input
	tf := f.contents.terraform[_]
	some ws in tf.cloud[_].workspaces
	not contains(ws.name, "-")
	contains(ws.name, "_")
	v := {
		"path": f.path,
		"rule": "workspace_separator",
		"msg": sprintf("%s: workspace 名 %q は _ 区切り。- を使うこと", [f.path, ws.name]),
	}
}
