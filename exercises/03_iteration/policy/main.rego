package main

import rego.v1

# some: 条件を満たした件だけ残す (列挙)
deny contains msg if {
	some name, svc in input.services   # name = "api", svc = その値
	svc.replicas < 2
	msg := sprintf("%s: replicas は 2 以上", [name])
}

# every: 全件満たすときだけ真
all_owned if {
	every svc in input.services { svc.owner != "" }
}
