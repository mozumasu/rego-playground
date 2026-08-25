# rego-playground

Rego (OPA / conftest のポリシー言語) を手を動かして学ぶハンズオン。

## 進め方

各章の `policy/*.rego` に `# TODO` があるので、そこを埋めて
**テストが全部通ったら合格**。テストが採点者になっている。

```bash
cd exercises/01_hello_deny
conftest verify -p policy/
```

`FAIL` が出たら実装を直して再実行。全 `passed` になったら次の章へ。

## 章立て

| 章 | テーマ | 学ぶこと |
| --- | --- | --- |
| [01_hello_deny](exercises/01_hello_deny/) | はじめての deny | package / deny ルール / `if` / `input` |
| [02_undefined](exercises/02_undefined/) | undefined と default | ルールは「クエリ」/ undefined vs false / `not` |
| [03_iteration](exercises/03_iteration/) | 繰り返し | `some ... in` / `every` / set への `contains` |
| [04_helpers](exercises/04_helpers/) | ヘルパーと組み込み関数 | 関数定義 / `split` / `sprintf` / `net.cidr_contains` |
| [05_write_tests](exercises/05_write_tests/) | テストを書く | `*_test.rego` / `with input as` / 境界値 |
| [06_terraform_plan](exercises/06_terraform_plan/) | 実戦: Terraform plan | plan JSON の構造 / fail-closed / negation の罠 |

## セットアップ

direnv + Nix flake で `conftest` / `opa` / `terraform` が入る:

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
