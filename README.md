# rego-playground

Rego (OPA / conftest のポリシー言語) を手を動かして学ぶハンズオン。

## 進め方

各章の `policy/*.rego` に `# TODO` があるので、そこを埋めて
**テストが全部通ったら合格**。テストが採点者になっている。

```bash
cd exercises/02_hello_deny
conftest verify -p policy/
```

`FAIL` が出たら実装を直して再実行。全 `passed` になったら次の章へ。

## 章立て

| 章 | テーマ | 学ぶこと |
| --- | --- | --- |
| [01_run_conftest](exercises/01_run_conftest/) | まず動かす (TODO なし) | `conftest test` の読み方 / `opa eval` で中身を見る / deny は conftest との約束 / `--namespace` |
| [02_hello_deny](exercises/02_hello_deny/) | はじめての deny | package / deny ルール / `if` / `input` |
| [03_undefined](exercises/03_undefined/) | 「キーが無い」は黙って通る | undefined vs false / 欠落を弾くなら `not x == 値` / 同名ルール = OR |
| [04_silent_failure](exercises/04_silent_failure/) | 壊しても静か | タイポで死んでも緑になる / `0 tests` の罠 / テストが唯一の検出器 |
| [05_iteration](exercises/05_iteration/) | 繰り返し | `some ... in` / `every` / set への `contains` |
| [06_helpers](exercises/06_helpers/) | ヘルパーと組み込み関数 | 関数定義 / `split` / `sprintf` / `net.cidr_contains` |
| [07_write_tests](exercises/07_write_tests/) | テストを書く | `*_test.rego` / `with input as` / 境界値 |
| [08_terraform_plan](exercises/08_terraform_plan/) | 実戦: Terraform plan | plan JSON の構造 / fail-closed / negation の罠 |
| [09_conftest_hcl](exercises/09_conftest_hcl/) | 実戦: Terraform の HCL | `--parser hcl2 --combine` / パスとの突合 / undefined で対象外にする |
| [10_exceptions_allowlist](exercises/10_exceptions_allowlist/) | 実戦: 例外 allowlist | `finding` → `deny` の分離 / `--data` / 理由の明示を強制する設計 |
| [11_metadata_docs](exercises/11_metadata_docs/) | METADATA とドキュメント生成 | `# METADATA` 注釈 / `conftest doc` / rule 識別子の一覧を生成する |

01〜07 が Rego の言語、08〜11 が conftest で Terraform を検査する実務パターン。
スライド「Rego / conftest 入門」の章立てと同じ順に並んでいる (2 章 = 01〜03、3 章 = 04〜07、4 章 = 08〜09、5 章 = 10〜11)。

## conftest コマンド早見表

| やりたいこと | コマンド |
| --- | --- |
| ポリシー自体のテスト (`*_test.rego`) | `conftest verify -p policy/` |
| JSON / YAML を検査 | `conftest test -p policy/ input.json` |
| plan JSON を検査 | `terraform show -json tfplan > plan.json && conftest test -p policy/ plan.json` |
| `.tf` を検査 (パスも見る) | `conftest test -p policy/ --parser hcl2 --combine $(find . -name '*.tf')` |
| 例外 allowlist を渡す | `... --data exceptions.yaml` |
| 別パッケージのポリシーを使う | `... --namespace naming` / `--all-namespaces` (既定は `main` だけ) |
| ルールの値をそのまま見る (デバッグ) | `opa eval -d policy/main.rego -i input.json 'data.main' --format pretty` |
| 入力がどう見えるか確認 | `conftest parse --parser hcl2 --combine path/to/terraform.tf` |
| 注釈からドキュメント生成 | `mkdir -p out && conftest doc -t table.tmpl policy/ -o out/` |

`test` は「実データにポリシーを当てる」、`verify` は「ポリシーのテストを走らせる」。混同しやすいので注意。

## セットアップ

direnv + Nix flake で `conftest` / `opa` が入る (terraform は 08 章の発展で使うだけなので入れていない):

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
