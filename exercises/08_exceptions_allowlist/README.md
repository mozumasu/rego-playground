# 08. 実戦: 例外 allowlist と rule ごとの level (finding → deny / warn)

07 章のポリシーを本番のリポジトリに入れると、既存の workspace が何十件も引っかかる。
リネームは state の付け替えを伴うのですぐには直せない。かといって rego に例外をハードコードすると
例外が増えるたびにポリシーが汚れる。実務では **「禁止」ではなく「理由の明示を強制」する**。

もう 1 つ。共通ポリシーに新しい rule を足すと、呼び出し側のリポジトリ全部の CI が同時に落ちる。
rule ごとに level (deny / warn / disabled) を持たせ、**新 rule は warn で入れて、全リポジトリが緑になったら deny に上げる**。

スライド「免除の判定は 1 箇所に集める」「例外は理由の明示を強制」「新 rule は warn で入れて deny に上げる」
「level 解決の部品」「rule 単位の免除は rules: で level を下げる」のコードをそのまま置いてある。

- `policy/main.rego` — ルールは `deny` を書かず、`finding {path, rule, msg}` を出すだけ (2 本)
- `policy/exceptions.rego` — `deny` / `warn` を書くのはここだけ。finding を 1 件ずつ allowlist と突合し、level で振り分ける
- `policy/lib/levels.rego` — level の解決。呼び出し側 `rules:` > ポリシー側 `levels.yaml` > deny (どちらにも無い rule は deny)
- `policy/levels.yaml` — ポリシー側の既定 level。rule 一覧を兼ねる
- `.conftest-exceptions.yaml` — 呼び出し側 (各リポジトリ) の allowlist。`exceptions:` はファイル単位の免除、`rules:` は rule 単位の level 上書き

## 1. allowlist なしで走らせる

```bash
conftest test -p policy/ --namespace hcl --parser hcl2 --combine \
  --data policy/levels.yaml $(find terraform -name '*.tf')
```

```text
FAIL - Combined - hcl - terraform/environments/production/web/terraform.tf: workspace 名 "app-staging-web" に "production" が無い
FAIL - Combined - hcl - terraform/environments/staging/legacy/terraform.tf: workspace 名 "app_staging_legacy" は _ 区切り。- を使うこと

3 tests, 1 passed, 0 warnings, 2 failures, 0 exceptions
```

同名の `finding contains v` が 2 本あり、それぞれの出力は 1 つの集合 `finding` に合算される。
`exceptions.rego` はその集合を `some v in finding` で 1 件ずつ見て、`levels.level(v.rule)` が `deny` なら `deny` に入れる。

`--data policy/levels.yaml` を外しても結果は同じ。`levels.yaml` に無い rule の level は deny になる (fail-closed)。

## 2. allowlist を渡す

```bash
conftest test -p policy/ --namespace hcl --parser hcl2 --combine \
  --data policy/levels.yaml --data .conftest-exceptions.yaml $(find terraform -name '*.tf')
```

```text
2 tests, 2 passed, 0 warnings, 0 failures, 0 exceptions
```

`--data` は複数回渡せる。各 YAML はその先頭キーのまま `data.levels` / `data.exceptions` に入る
(実務ではポリシーリポジトリの `levels.yaml` と、呼び出し側リポジトリの `.conftest-exceptions.yaml`)。
2 件とも `path` と `rule` が一致し `reason` があるので免除された。

## Q1. reason を空にすると?

`.conftest-exceptions.yaml` の 1 つ目の `reason` を `""` にして 2. を再実行する。

<details><summary>答え</summary>

```text
FAIL - Combined - hcl - terraform/environments/production/web/terraform.tf: workspace 名 "app-staging-web" に "production" が無い

2 tests, 1 passed, 0 warnings, 1 failure, 0 exceptions
```

その 1 件だけ FAIL に戻る。免除は「消す」のではなく「理由つきで残す」。確認したら戻す。

</details>

## Q2. rule 単位で全ファイルを免除しよう

`workspace_separator` を、ファイルを指定せずリポジトリ全体で免除する。
`.conftest-exceptions.yaml` の 2 つ目 (`workspace_separator` の行) を消し、`rules:` を足して 2. を再実行する。

<details><summary>答え</summary>

```yaml
rules:
  workspace_separator:
    level: disabled
    reason: "命名規約制定前からの workspace。既存名を維持"
exceptions:
  - path: terraform/environments/production/web/terraform.tf
    rule: workspace_env_match
    reason: "移行中。2026-10 のメンテナンスウィンドウでリネームする"
```

```text
2 tests, 2 passed, 0 warnings, 0 failures, 0 exceptions
```

`lib/levels.rego` の `level()` が `data.rules` を先に見て `disabled` を返すので、`deny` にも `warn` にも入らない。
既定 (deny) より下げるので `reason` が必須。空にすると上書きは無視され、既定の deny で評価されて
`staging/legacy` の 1 件が FAIL に戻る。上げるのは自由。

`disabled` は新規ファイルにも効いてしまう。ファイル単位で書けるならファイル単位で。確認したら戻す。

</details>

## 3. 新 rule は warn で入れて、deny に上げる

`workspace_separator` を今日足したばかりの rule だとする。`policy/levels.yaml` で `warn` にし、
`.conftest-exceptions.yaml` の 2 つ目 (`workspace_separator` の免除) を消して 2. を再実行する。

```text
WARN - Combined - hcl - terraform/environments/staging/legacy/terraform.tf: workspace 名 "app_staging_legacy" は _ 区切り。- を使うこと

2 tests, 1 passed, 1 warning, 0 failures, 0 exceptions
```

exit code は 0 で CI は落ちない (`--fail-on-warn` を付けない限り)。`--output github` を付けると PR にアノテーションで出る:

```text
::warning file=Combined,line=1::terraform/environments/staging/legacy/terraform.tf: workspace 名 "app_staging_legacy" は _ 区切り。- を使うこと
```

新 rule は warn で入れる → 各リポジトリが直すか `rules:` で免除する → 全リポジトリで 0 failures を確認 → `levels.yaml` を `deny` に上げる。
先回りの免除 PR を全リポジトリに出してからでないと rule をマージできない、という状態が無くなる。確認したら戻す。

## 4. なぜ finding なのか

各 deny ルールが `not excepted(...)` を呼ぶ約束にすると、1 本書き忘れただけで allowlist が効かなくなり、
しかもエラーにならない (05 章の silent pass)。finding → deny / warn の変換を 1 箇所に置けば、ルール側は免除の存在も level も知らなくてよい。

`rule` の typo は「一致しない」だけでエラーにならない。免除が効かないときはまず typo を疑う (09 章でテストにする)。
