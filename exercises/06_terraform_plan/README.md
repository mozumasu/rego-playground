# 06. 実戦: Terraform plan JSON を検査する

仕上げとして、実務 (terraform-aws-findy-platform の conftest 導入) と同じ
**VPC CIDR 割当標準ポリシー**を plan JSON に対して書く。

## plan JSON の構造

`terraform show -json tfplan` の出力で見るのはほぼ `resource_changes` だけ:

```json
{
  "resource_changes": [
    {
      "address": "module.network.aws_vpc.this",
      "type": "aws_vpc",
      "mode": "managed",
      "change": {
        "actions": ["create"],
        "after": { "cidr_block": "10.0.0.0/16", ... },
        "after_unknown": { "id": true, ... }
      }
    }
  ]
}
```

- `actions`: `["create"]` / `["update"]` / `["delete"]` / `["delete", "create"]` (replace)
- `after`: plan 後の値。**plan 時に確定しない値はここに入らず `after_unknown` に載る**

## ⚠️ negation の罠 (実務で踏んだバグ)

「cidr_block が無ければ deny」を素直に書くと動かない:

```rego
# ❌ 動かない
deny contains msg if {
	some rc in vpc_creations
	not is_string(rc.change.after.cidr_block)  # ← 罠
	msg := "..."
}
```

OPA コンパイラは関数引数の参照を `not` の**外**に巻き上げるため、
キーが欠落していると代入自体が undefined になり、rule 全体が成立しない
(= deny が出ない = fail-open)。正しくは `object.get` で必ず値を得る:

```rego
# ✅ 正しい
cidr := object.get(rc.change, ["after", "cidr_block"], null)
not is_string(cidr)
```

## 課題

`policy/vpc_cidr.rego` に実装せよ:

1. `vpc_creations` — `resource_changes` から `type == "aws_vpc"` かつ
   `mode == "managed"` かつ actions に `"create"` を含むものを集める set ルール
2. `cidr_allowed(cidr)` — 04 章と同じ (/16 かつ 10.0.0.0/12 or 172.16.0.0/12 内)
3. deny その 1 — cidr が文字列で、`cidr_allowed` でなければ
   `sprintf("%s: VPC CIDR %q は割当標準外", [rc.address, cidr])`
4. deny その 2 (fail-closed) — cidr が文字列でなければ (未確定/欠落)
   `sprintf("%s: plan 時に VPC CIDR が確定していない", [rc.address])`
   **↑ 上の罠を避けて object.get で書くこと**

## 実行

```bash
conftest verify -p policy/                 # 採点
conftest test -p policy/ plans/ok.json     # 準拠 plan → pass するはず
conftest test -p policy/ plans/ng.json     # 違反 plan → FAIL するはず
```

余力があれば `terraform/` に本物の `aws_vpc` を書き、
`terraform plan -out=tfplan && terraform show -json tfplan > plan.json` で
実物の plan JSON を作って検査してみるとよい。
