# 06. 実戦: Terraform plan JSON を検査する

スライド「plan JSON はどんな形か」の deny を `policy/vpc_cidr.rego` に置いてある。
plan を打てる環境が無くても試せるよう、plan JSON を 2 つ同梱している。

- `plans/ok.json` — VPC の CIDR が `10.3.0.0/16` (割当内)
- `plans/ng.json` — `192.168.0.0/16` の VPC と、CIDR が plan 時に決まらない VPC (`aws_vpc.ipam`。IPAM = AWS の IP Address Manager から自動採番するので、CIDR は apply まで決まらない)

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
(02 章の「キーが無いと黙る」と同じ)。

## Q1. ng.json を 1 件だけ FAIL にしよう

`plans/ng.json` だけを書き換えて、`module.network.aws_vpc.this` の FAIL を消す (ipam の FAIL は残す)。

<details><summary>答え</summary>

`"cidr_block": "192.168.0.0/16"` を `10.0.0.0/12` に含まれる CIDR (`10.5.0.0/16` など) にする。
1 本目の deny は `net.cidr_contains` だけを見ているので、/16 でなくても通る (04 章の `cidr_allowed` より緩い)。

</details>

## Q2. CIDR 未確定の `aws_vpc.ipam` はどう捕まえている?

スライドの deny (1 本目) は `cidr := rc.change.after.cidr_block` で値を取るので、`after` に `cidr_block` が無い ipam は
この行で不成立になり黙って通る。`policy/vpc_cidr.rego` の 2 本目の deny を読んで、どう捕まえているか確かめる。

<details><summary>答え</summary>

```rego
	cidr := object.get(rc.change, ["after", "cidr_block"], null)   # 無ければ null
	not is_string(cidr)
```

`object.get` で「無ければ null」に落としてから判定するので、代入で止まらず `not` まで届く。

試しに 2 本目を `object.get` を使わず `not is_string(rc.change.after.cidr_block)` と書き換えて `plans/ng.json` を通す:

```text
FAIL - plans/ng.json - main - module.network.aws_vpc.this: CIDR 192.168.0.0/16 は割当外

2 tests, 1 passed, 0 warnings, 1 failure, 0 exceptions
```

ipam の FAIL が消える。`after` に `cidr_block` が無いので、`not` に届く前に参照が不成立になりルールごと消える。
未確定の CIDR が黙って通る = fail-open。確認したら戻す。

</details>
