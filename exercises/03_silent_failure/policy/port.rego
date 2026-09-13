package main

import rego.v1

allowed_ports := {443}

# 待ち受けポートは allowed_ports のいずれか
denny contains msg if {
	not input.port in allowed_ports
	msg := sprintf("ポート %d は許可されていません。443 を使ってください", [input.port])
}
