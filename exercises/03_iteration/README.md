# 03. 繰り返し — some と every

## some ... in : 「1 つでもあれば」

Rego に for ループはない。代わりに「条件を満たす要素を**探索**する」と考える。

```rego
deny contains msg if {
	some port in input.ports        # ports の各要素を port に束縛して探索
	port < 1024
	msg := sprintf("特権ポート %d は禁止", [port])
}
```

`some port in ...` は該当する要素**ごと**にルールが成立するので、
違反が 3 つあれば deny メッセージも 3 つ生まれる (deny は set なので重複は消える)。

オブジェクトはキーと値を取れる: `some name, cfg in input.services`

## every : 「全部満たすとき」

```rego
all_ports_safe if {
	every port in input.ports {
		port >= 1024
	}
}
```

`some` は存在 (∃)、`every` は全称 (∀)。「1 つでも違反したら deny」は some、
「全て満たすときだけ allow」は every。

## 課題

`input` は `{"services": {"web": {...}, "db": {...}}}` の形。実装せよ:

1. いずれかのサービスの `ports` に 1024 未満があれば deny
   (メッセージ: `sprintf("%s: 特権ポート %d は禁止", [name, port])`)
2. `replicas` が全サービスで 2 以上のときだけ成立する `ha_ready` ルール
   (every を使う)
3. `ha_ready` でなければ deny (メッセージ: `"全サービス replicas 2 以上が必要"`)

## 実行

```bash
conftest verify -p policy/
```
