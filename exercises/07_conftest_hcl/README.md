# 07. 実戦: Terraform の HCL を検査する (workspace 名)

06 章は plan JSON を検査した。plan JSON には「実際に作られる値」が入るが、
**`terraform { cloud { workspaces { name } } }` の workspace 名は plan JSON に現れない**。
production ディレクトリが staging の state を掴む事故はここで起きるので、`.tf` そのものを読んで検査する。

`policy/main.rego` はスライド「HCL ポリシーの例」の `path_env` と、その deny 版。
`terraform/environments/production/web/terraform.tf` は staging からコピーして名前を直し忘れている。

## 1. .tf が input になるとどんな形か

```bash
conftest parse --parser hcl2 terraform/environments/staging/web/terraform.tf
```

```json
{ "terraform": [{ "cloud": [{ "organization": "example-org",
                               "workspaces": [{ "name": "app-staging-web" }] }] }] }
```

ブロック名が JSON のキーになり、値は **1 個でも配列**。Rego では `[_]` を 1 段ずつ挟んで辿る。

## 2. ファイルのパスも検査したい: --combine

```bash
conftest parse --parser hcl2 --combine terraform/environments/staging/web/terraform.tf
```

`[{ "path": "terraform/environments/staging/web/terraform.tf", "contents": { ... } }]` の形になる。
`--combine` で input がファイルの配列になり、`path` が使える。`contents` は 1. の parse 結果そのもの。

## 3. ポリシーを当てる

```bash
conftest test -p policy/ --namespace hcl --parser hcl2 --combine $(find terraform -name '*.tf')
```

```text
FAIL - Combined - hcl - terraform/environments/production/web/terraform.tf: workspace 名 "app-staging-web" に "production" が無い

1 test, 0 passed, 0 warnings, 1 failure, 0 exceptions
```

- `--namespace hcl`: ポリシーが `package hcl` なので指定する (既定は main だけ)
- `modules/vpc/main.tf` には cloud ブロックが無い。`path_env` も undefined になるので deny は成立せず、検査対象外を「何もしない」で表せる

## 4. --combine を外すとどうなるか

```bash
conftest test -p policy/ --namespace hcl --parser hcl2 $(find terraform -name '*.tf')
```

```text
4 tests, 4 passed, 0 warnings, 0 failures, 0 exceptions
```

ファイルごとに評価され `path` が input に入らないので、`some f in input` が成り立たず deny が出ない。
パスを見るポリシーには `--combine` が要る。

## 5. path_env を単体で見る

```bash
opa eval -d policy/ 'data.hcl.path_env("terraform/environments/staging/web/terraform.tf")' -f pretty
```

`"staging"` が返る。`split` → `["terraform", "environments", "staging", ...]`、`environments` が 1 番目なので `parts[2]`。
