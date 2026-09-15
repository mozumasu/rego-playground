package hcl

import rego.v1

# environments/<env>/... の <env> を取る
path_env(path) := parts[i + 1] if {
	parts := split(path, "/")
	some i
	parts[i] == "environments"
}

# METADATA
# title: workspace_env_match
# description: environments/<env>/ の env が workspace 名に含まれること
# custom:
#   source: 社内の workspace 命名規約
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

# METADATA
# title: workspace_separator
# description: workspace 名の区切りは - を使い、_ を使わないこと
# custom:
#   source: 社内の workspace 命名規約
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
