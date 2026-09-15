# 06. 実戦: Terraform plan JSON を検査する

スライド「plan JSON はどんな形か」の deny を `policy/vpc_cidr.rego` に置いてある。
plan を打てる環境が無くても試せるよう、plan JSON を 2 つ同梱している。

- `plans/ok.json` — VPC の CIDR が `10.3.0.0/16` (割当内)
- `plans/ng.json` — `192.168.0.0/16` の VPC と、CIDR が plan 時に決まらない VPC (IPAM 採番)

自分の Terraform で作るなら (init 済みで provider の認証が通る環境で):

```bash
terraform plan -out=tfplan
terraform show -json tfplan > plan.json
```

## 1. plan JSON の形を見る

```bash
jq '.resource_changes[] | {address, type, change: {actions: .change.actions, after: .change.after}}' plans/ng.json
```

見るのはほぼ `resource_changes` だけ。各要素の `type` で対象を絞り、`actions` で create / update を選び、
`after` に適用後の値が入る。

## 2. 2 つの plan を通す

```bash
conftest test -p policy/ plans/ok.json
conftest test -p policy/ plans/ng.json
```

```text
2 tests, 2 passed, 0 warnings, 0 failures, 0 exceptions
FAIL - plans/ng.json - main - module.network.aws_vpc.ipam: plan 時に CIDR が確定していない
FAIL - plans/ng.json - main - module.network.aws_vpc.this: CIDR 192.168.0.0/16 は割当外
```

`opa eval -d policy/ -i plans/ng.json 'data.main.deny' -f pretty` でも同じ 2 件が見える。

## 3. 未確定の値はどこにあるか

```bash
jq '.resource_changes[1].change' plans/ng.json
```

```json
{ "actions": ["create"], "after": {}, "after_unknown": { "id": true, "cidr_block": true } }
```

plan 時に決まらない値は `after` に無く `after_unknown` に入る。
`policy/vpc_cidr.rego` の 2 本目の deny は、これを `object.get` で `null` に落としてから判定している。
`not is_string(rc.change.after.cidr_block)` と直接書くと、キーが無い時点でルールごと消えて通ってしまう
(02 章の「キーが無いと黙る」と同じ)。試すなら 2 本目の deny をそう書き換えて、ipam の FAIL が消えるのを見る。
