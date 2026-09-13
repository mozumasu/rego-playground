# 08. 実戦: Terraform の HCL を検査する (workspace 名)

06 章は plan JSON を検査した。plan JSON には「実際に作られる値」が入るが、
**`terraform { cloud { workspaces { name } } }` の workspace 名は plan JSON に現れない**。
production ディレクトリが staging の state を掴む事故はここで起きるので、
`.tf` ファイルそのものを読んで検査する。

## conftest で HCL を読む

```bash
conftest test -p policy/ --parser hcl2 --combine $(find terraform -name '*.tf')
```

- `--parser hcl2`: `.tf` を JSON 相当の構造に変換して `input` にする
- `--combine`: 複数ファイルを **1 回の評価にまとめる**。`input` が
  `[{path, contents}, ...]` の配列になり、`path` が使えるようになる
  (ファイルパスとの突合や、ファイル横断の重複チェックにはこれが要る)

`--combine` したときの `input` の形は `conftest parse` で確認できる:

```bash
conftest parse --parser hcl2 --combine terraform/environments/staging/web/terraform.tf
```

```json
[
  {
    "path": "terraform/environments/staging/web/terraform.tf",
    "contents": {
      "terraform": [{ "cloud": [{ "workspaces": [{ "name": "app-staging-web" }] }] }]
    }
  }
]
```

**ブロックは 1 個しか無くても配列になる**。`contents.terraform[_].cloud[_].workspaces[_].name` と
`[_]` (または `some ... in`) で潜る。

## パスから env を取る

`environments/<env>/...` の `<env>` を取り出したい。`split(path, "/")` して
`"environments"` の**次**の要素を返す。`environments` が何番目に来るかは
実行場所で変わる (`terraform/environments/...` かもしれない) ので、位置を決め打ちしない。

```rego
path_env(path) := env if {
	parts := split(path, "/")
	some i
	parts[i] == "environments"
	env := parts[i + 1]
}
```

`environments` が無いパス (`modules/vpc/main.tf` など) では `path_env` が undefined になり、
それを使う deny も成立しない。**検査対象外を「何もしない」で表現できる**のが Rego らしいところ。

## 課題

`policy/main.rego` に実装せよ:

1. `workspace_name(doc)` — `doc.contents.terraform[_].cloud[_].workspaces[_].name` を返す関数
2. `path_env(path)` — 上のとおり
3. `segments(name)` — workspace 名を `-` と `_` の両方で分割した set
   (`replace` で `_` を `-` に寄せてから `split` すると楽)
4. deny — `env` が `segments(name)` に含まれていなければ
   `sprintf("%s: workspace 名 %q に env %q が含まれていない", [doc.path, name, env])`

## 実行

```bash
conftest verify -p policy/                                                    # 採点
conftest test -p policy/ --parser hcl2 --combine $(find terraform -name '*.tf')  # 実データ
```

`terraform/environments/production/web/terraform.tf` は staging からコピーしたまま
名前を直し忘れている (実務で何度も起きた形)。ここだけ FAIL になれば正解。
