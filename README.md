# rego-playground

Rego (OPA / conftest のポリシー言語) を手を動かして学ぶハンズオン。

## 進め方

各章にスライドと同じコードと入力が置いてある。README のコマンドを上から打って、出力を読む。
TODO は無い。「試すなら」と書いてある箇所は、ファイルを書き換えて挙動が変わるのを見る。

```bash
cd exercises/01_run_conftest
conftest test -p policy/ input.json
```

## 章立て

| 章 | テーマ | 学ぶこと |
| --- | --- | --- |
| [01_run_conftest](exercises/01_run_conftest/) | まず動かす | `conftest test` の読み方 / `opa eval` で中身を見る / deny は conftest との約束 / `--namespace` |
| [02_undefined](exercises/02_undefined/) | 「キーが無い」は黙って通る | undefined vs false / 欠落を弾くなら `not x == 値` |
| [03_iteration](exercises/03_iteration/) | 繰り返し | `some ... in` / `every` / set への `contains` |
| [04_helpers](exercises/04_helpers/) | ヘルパーと組み込み関数 | 関数定義 / `split` / `sprintf` / `net.cidr_contains` |
| [05_silent_failure](exercises/05_silent_failure/) | 壊しても静か、テストが採点者 | タイポで死んでも緑になる / `with input as` の 3 ケース / テストが唯一の検出器 |
| [06_terraform_plan](exercises/06_terraform_plan/) | 実戦: Terraform plan | `resource_changes` の形 / 未確定の値は `after_unknown` |
| [07_conftest_hcl](exercises/07_conftest_hcl/) | 実戦: Terraform の HCL | `conftest parse` / `--combine` でパスが入る / `path_env` |
| [08_exceptions_allowlist](exercises/08_exceptions_allowlist/) | 実戦: 例外 allowlist | `finding` → `deny` の分離 / `--data` / 理由の明示を強制する設計 |
| [09_write_tests](exercises/09_write_tests/) | テストの規律 | 最小 3 ケース / `count == N` 完全一致 / rule 識別子と allowlist の固定 |
| [10_metadata_docs](exercises/10_metadata_docs/) | METADATA とドキュメント生成 | `# METADATA` 注釈 / `conftest doc` / rule 識別子の一覧を生成する |

01〜05 が Rego の言語、06〜08 が conftest で Terraform を検査する実務パターン、09〜10 がテストとドキュメントの運用。
スライド「Rego / conftest 入門」の章立てと同じ順に並んでいる (2〜3 章 = 01〜05、4 章 = 06〜07、5 章 = 08〜10)。

## conftest コマンド早見表

| やりたいこと | コマンド |
| --- | --- |
| ポリシー自体のテスト (`*_test.rego`) | `conftest verify -p policy/` |
| JSON / YAML を検査 | `conftest test -p policy/ input.json` |
| plan JSON を検査 | `terraform show -json tfplan > plan.json && conftest test -p policy/ plan.json` |
| `.tf` を検査 (パスも見る) | `conftest test -p policy/ --parser hcl2 --combine $(find . -name '*.tf')` |
| 例外 allowlist を渡す | `... --data exceptions.yaml` |
| 別パッケージのポリシーを使う | `... --namespace hcl` / `--all-namespaces` (既定は `main` だけ。07〜10 章は `package hcl`) |
| ルールの値をそのまま見る (デバッグ) | `opa eval -d policy/main.rego -i input.json 'data.main' --format pretty` |
| 入力がどう見えるか確認 | `conftest parse --parser hcl2 --combine path/to/terraform.tf` |
| 注釈からドキュメント生成 | `mkdir -p out && conftest doc -t table.tmpl policy/ -o out/` |

`test` は「実データにポリシーを当てる」、`verify` は「ポリシーのテストを走らせる」。混同しやすいので注意。

## セットアップ

direnv + Nix flake で `conftest` / `opa` が入る (terraform は 06 章の発展で使うだけなので入れていない):

```bash
direnv allow
conftest --version
```

## 実験用ワンライナー

Rego の式をその場で試したいとき (REPL):

```bash
opa run
> 1 + 1
> "10.0.0.0/16" == sprintf("%s/16", ["10.0.0.0"])
```

## 参考

- [OPA Policy Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Rego Playground (Web)](https://play.openpolicyagent.org/)
- [conftest](https://www.conftest.dev/)
- [Rego Style Guide](https://www.openpolicyagent.org/docs/style-guide) (METADATA・パッケージ構成の推奨)
