package main

import rego.v1

# --- 09 章の完成形。ここに METADATA を足す ---

workspace_name(doc) := name if {
	some tf in doc.contents.terraform
	some cloud in tf.cloud
	some ws in cloud.workspaces
	name := ws.name
}

path_env(path) := env if {
	parts := split(path, "/")
	some i
	parts[i] == "environments"
	env := parts[i + 1]
}

segments(name) := {s | some s in split(replace(name, "_", "-"), "-")}

# TODO(1): この finding の直前に # METADATA (title / description / custom.source) を書く
finding contains v if {
	some doc in input
	name := workspace_name(doc)
	env := path_env(doc.path)
	not env in segments(name)
	v := {
		"path": doc.path,
		"rule": "workspace_env_match",
		"msg": sprintf("%s: workspace 名 %q に env %q が含まれていない", [doc.path, name, env]),
	}
}

# TODO(2): こちらにも
finding contains v if {
	some doc in input
	name := workspace_name(doc)
	not contains(name, "-")
	contains(name, "_")
	v := {
		"path": doc.path,
		"rule": "workspace_separator",
		"msg": sprintf("%s: workspace 名 %q は `_` 区切り。`-` を使うこと", [doc.path, name]),
	}
}
