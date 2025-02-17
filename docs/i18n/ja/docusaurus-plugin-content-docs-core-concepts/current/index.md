---
sidebar_position: 1
---

# 概要

Hydraは、Cardanoのレイヤー2スケーラビリティソリューションで、低遅延と高スループットによるトランザクション速度の向上とコストの最小化を目的としています。

[Hydra Head](https://eprint.iacr.org/2020/299.pdf)は Hydraファミリーの最初のプロトコルであり、同型のマルチパーティステートチャネルに依存する、より高度な展開シナリオの基礎を具現化するものです。Hydra Headプロトコルには様々な種類と拡張がありますが、まずは基本的なHydra Headのライフサイクル全体と、レイヤー1（`Layer 1`）とレイヤー2（`Layer 2`）の間の同型の状態遷移をどのように実現するかを見ていきましょう。

![](./hydra-head-lifecycle.svg)

Hydra Headは、オンラインで応答性の高い参加者のグループによって形成されます。参加者は、参加者リストを含むいくつかのパラメータをオンチェーンで告知することによってHeadを初期化（`Initial`）します。その後、参加者はCardanoメインチェーンからの未使用トランザクションアウトプット（UTXO）をHeadにコミット（`Commit`）し、すべてのUTXOが回収（`Collect`）されると初期状態（`U0`）としてHydra Headで利用できるようになります。回収前の任意の時点で、参加者はプロセスを中止して資金を回収することもできます。

開いている間は、Hydraノードを介してHydra Headを使用し、Headのネットワーク上でトランザクションを送信することができます。トランザクションの形式とプロパティはメインチェーンと同じです。 これらは「同型」です。UTXOエントリが消費され、新しいUTXOエントリがHydra Headに作成されると、すべての参加者はいわゆるスナップショット（`U1..Un`）で新しい状態を確認し、合意する必要があります。

参加者は誰でも、合意された状態を使用してHeadを閉じることができます。たとえば、メインネットでキャッシュアウトしたい場合、または別のパーティがHeadの進化を誤動作または停止させた場合です。メインチェーンの最終状態に異議（`Contest`）を唱えるメカニズムがあります。最終的に、ファンアウト（`Fanout`）トランザクションは、最終的に合意された状態を配布し、実質的にHeadにのみ存在していたものをレイヤー1で利用できるようにします。

```mdx-code-block
import DocCardList from '@theme/DocCardList';
import {useDocsSidebar} from '@docusaurus/theme-common';

<DocCardList items={useDocsSidebar().filter(({ docId }) => docId != "index")}/>
```
