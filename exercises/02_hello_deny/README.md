# 01. はじめての deny

## Rego の最小知識

Rego のファイルは **package 宣言** で始まる。conftest はデフォルトで `package main` の
`deny` / `warn` / `violation` ルールを評価する。

```rego
package main

import rego.v1

deny contains msg if {
	input.debug == true
	msg := "debug モードは禁止"
}
```

読み方:

- `input` = 検査対象の JSON/YAML 全体。`input.debug` でキーを辿る
- `deny contains msg if { ... }` = 「`{ ... }` 内の条件が**全部成立**したら、`msg` を deny 集合に追加する」
- 条件は上から順に AND。1 つでも成立しなければそのルールは何も生まない (エラーではない)
- `:=` は代入、`==` は比較

つまり Rego は「手続き」ではなく **「こういう条件のものはダメ」という宣言の集まり**。

## 課題

`input.json` はデプロイ設定。次のルールを `policy/main.rego` に実装せよ:

1. `environment` が `"production"` かつ `debug` が `true` なら deny
   (メッセージ: `"production で debug は有効にできない"`)
2. `replicas` が `1` 未満なら deny
   (メッセージ: `"replicas は 1 以上が必要"`)

## 実行

```bash
conftest verify -p policy/          # テスト = 採点 (これが全部通れば合格)
conftest test -p policy/ input.json # 実データに適用してみる
```
