# 08. 実戦: 例外 allowlist (finding → deny)

07 章のポリシーを本番のリポジトリに入れると、既存の workspace が何十件も引っかかる。
リネームは state の付け替えを伴うのですぐには直せない。かといって rego に例外をハードコードすると
例外が増えるたびにポリシーが汚れる。実務では **「禁止」ではなく「理由の明示を強制」する**。

スライド「免除の判定は 1 箇所に集める」「例外は理由の明示を強制」のコードをそのまま置いてある。

- `policy/main.rego` — ルールは `deny` を書かず、`finding {path, rule, msg}` を出すだけ (2 本)
- `policy/exceptions.rego` — `deny` を書くのはここだけ。finding を 1 件ずつ allowlist と突合する
- `.conftest-exceptions.yaml` — allowlist。`path` × `rule` で突合し、`reason` が空なら無効

## 1. allowlist なしで走らせる

```bash
conftest test -p policy/ --namespace hcl --parser hcl2 --combine $(find terraform -name '*.tf')
```

```text
FAIL - Combined - hcl - terraform/environments/production/web/terraform.tf: workspace 名 "app-staging-web" に "production" が無い
FAIL - Combined - hcl - terraform/environments/staging/legacy/terraform.tf: workspace 名 "app_staging_legacy" は _ 区切り。- を使うこと

2 tests, 0 passed, 0 warnings, 2 failures, 0 exceptions
```

同名の `finding contains v` が 2 本あり、それぞれの出力は 1 つの集合 `finding` に合算される。
`exceptions.rego` はその集合を `some v in finding` で 1 件ずつ見る。

## 2. allowlist を渡す

```bash
conftest test -p policy/ --namespace hcl --parser hcl2 --combine \
  --data .conftest-exceptions.yaml $(find terraform -name '*.tf')
```

```text
1 test, 1 passed, 0 warnings, 0 failures, 0 exceptions
```

`--data` で渡した YAML は、その先頭キー (`exceptions:`) のまま `data.exceptions` に入る。
2 件とも `path` と `rule` が一致し `reason` があるので免除された。

## Q1. reason を空にすると?

`.conftest-exceptions.yaml` の 1 つ目の `reason` を `""` にして 2. を再実行する。

<details><summary>答え</summary>

```text
FAIL - Combined - hcl - terraform/environments/production/web/terraform.tf: workspace 名 "app-staging-web" に "production" が無い

1 test, 0 passed, 0 warnings, 1 failure, 0 exceptions
```

その 1 件だけ FAIL に戻る。免除は「消す」のではなく「理由つきで残す」。確認したら戻す。

</details>

## Q2. rule 単位で全ファイルを免除しよう

`workspace_separator` を、ファイルを指定せずリポジトリ全体で免除する。`.conftest-exceptions.yaml` の 2 つ目を直す。

<details><summary>答え</summary>

```yaml
  - path: "*"
    rule: workspace_separator
    reason: "命名規約制定前からの workspace。既存名を維持"
```

`exceptions.rego` の 2 本目の `excepted` が `path == "*"` を見ている。既存リポジトリの grandfather 用で、新規ファイルにも効いてしまうので使いどころは限る。

</details>

## 4. なぜ finding なのか

各 deny ルールが `not excepted(...)` を呼ぶ約束にすると、1 本書き忘れただけで allowlist が効かなくなり、
しかもエラーにならない (05 章の silent pass)。finding → deny の変換を 1 箇所に置けば、ルール側は免除の存在を知らなくてよい。

`rule` の typo は「一致しない」だけでエラーにならない。免除が効かないときはまず typo を疑う (09 章でテストにする)。
