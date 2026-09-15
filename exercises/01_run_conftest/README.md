# 01. まず動かす — conftest test と opa eval

コードを書く前に、conftest と opa が何をしているかを手で確かめる章。
コマンドを打って出力を読む。

用意してあるファイル:

- `input.json` — チェック対象。conftest に渡すと、この中身がそのまま `input` になる
- `policy/debug.rego` — `package main` の deny 1 本
- `policy/naming.rego` — `package naming` の deny 1 本
- `policy/*_test.rego` — 採点用テスト

## 1. conftest test で実行する

```bash
conftest test -p policy/ input.json
```

```text
FAIL - input.json - main - production では debug を無効に

1 test, 0 passed, 0 warnings, 1 failure, 0 exceptions
```

読み方:

- `-p policy/` — このディレクトリの `*.rego` を全部読む
- `input.json` — 引数のファイルが `input` になる
- `FAIL - <ファイル> - <package 名> - <deny の msg>` — deny 集合に入った msg がそのまま 1 行になる
- 最後の行が集計。failure が 1 つでもあれば終了コードは 1 (CI はここで止まる)

`input.json` の `debug` を `false` にして再実行すると、deny は空になり `1 test, 1 passed` で終了コード 0 になる。試したら戻しておく。

## 2. package を分けると、指定した package だけ評価される

`policy/naming.rego` は `package naming`。既定では `main` しか見ない:

```bash
conftest test -p policy/ input.json                      # main だけ
conftest test -p policy/ --namespace naming input.json   # naming だけ
conftest test -p policy/ --all-namespaces input.json     # 両方
```

```text
FAIL - input.json - main - production では debug を無効に
FAIL - input.json - naming - 名前に _ は使えない

2 tests, 0 passed, 0 warnings, 2 failures, 0 exceptions
```

FAIL 行の 3 列目が package 名。入力の形が違うポリシー (plan JSON 用と HCL 用など) を
同じ `policy/` に置き、CI のジョブごとに `--namespace` で使い分けるのが実務での使い方。

## 3. opa eval で中身を見る

conftest は deny しか見せない。ルールの値をそのまま見たいときは OPA 本体のコマンドを使う:

```bash
opa eval -d policy/debug.rego -i input.json 'data.main' --format pretty
```

```json
{
  "deny": [
    "production では debug を無効に"
  ]
}
```

`data.main` は `package main` の中身。ルールが増えればここに並ぶ
(`-d policy/` とディレクトリを渡すとテストのルール `test_*` も並ぶ)。
ルールの中で使った `msg` は出てこない。ルールの外からは見えないローカル変数だから。

`-i` を付けないと `input` が無いので条件が成り立たず、`deny` は空になる:

```bash
opa eval -d policy/debug.rego 'data.main' --format pretty
```

## 4. deny という名前は Rego の予約語ではない

`policy/debug.rego` の `deny` を `mydeny` に書き換えて実行する:

```bash
conftest test -p policy/ input.json
```

```text
0 tests, 0 passed, 0 warnings, 0 failures, 0 exceptions
```

違反はあるのに緑。conftest が探しに来る名前は `deny` / `violation` / `warn` だけで、
`mydeny` は拾われない。`opa eval 'data.main'` で見ると `mydeny` は普通に存在している。
言語として決まっているのは予約語 (`package` `import` `if` `not` など) だけで、
`deny` は conftest との約束。確認したら `deny` に戻す。

## Q1. conftest test を通そう

`input.json` だけを書き換えて `conftest test -p policy/ input.json` を `passed` にする。

<details><summary>答え</summary>

`"debug": false` にする。`input.debug == true` が成り立たず deny が空になる。
`--all-namespaces` を付けている場合は `name` の `_` も直す必要がある。確認したら戻す。

</details>

## Q2. naming の deny だけを出そう

`main` の deny を出さず、`naming` の「名前に _ は使えない」だけを FAIL にするコマンドは?

<details><summary>答え</summary>

```bash
conftest test -p policy/ --namespace naming input.json
```

`--namespace` は評価する package を選ぶ。`main` は指定しなければ見ない。

</details>

## 5. テストが採点者

以降の章は `conftest verify` で採点する。ここでも走らせておく:

```bash
conftest verify -p policy/
```

```text
3 tests, 3 passed, 0 warnings, 0 failures, 0 exceptions, 0 skipped
```

`test` は実データにポリシーを当てる、`verify` はポリシーのテスト (`*_test.rego`) を走らせる。
