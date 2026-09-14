package main

import rego.v1

# --- 09 章のヘルパー (完成済み) ---

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

# --- ここから課題。deny は書かない (exceptions.rego が finding を deny にする) ---

# TODO(1): workspace_env_match — 09 章の deny を finding に書き換える
# v は {"path": doc.path, "rule": "workspace_env_match", "msg": <07 と同じ msg>}
finding contains v if {
	false # ここを実装する (この行は消す)
	v := {"path": "TODO", "rule": "workspace_env_match", "msg": "TODO"}
}

# TODO(2): workspace_separator — 名前に "-" が無く "_" があれば finding
# v は {"path": doc.path, "rule": "workspace_separator",
#       "msg": sprintf("%s: workspace 名 %q は `_` 区切り。`-` を使うこと", [doc.path, name])}
finding contains v if {
	false # ここを実装する (この行は消す)
	v := {"path": "TODO", "rule": "workspace_separator", "msg": "TODO"}
}
