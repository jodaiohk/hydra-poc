---
sidebar_label: 'ベンチマーク'
sidebar_position: 1
---

# ベンチマークと制限事項

この項目では、Hydra Headオンチェーンプロトコルの既知の制限に関する最新データを提供します。Cardanoのトランザクション（およびブロック）には、トランザクションサイズ、実行コスト、インプットとアウトプットの数に制限があります。これらはネットワークパラメータに依存し、Headに参加できるパーティーの数、HeadにコミットできるUTXOの数、ファンアウトできる数など、Headプロトコルの機能に影響を及ぼします。オンチェーンスクリプトとトランザクションが成熟し、最適化され、基礎となるCardanoチェーンがより多くのパラメータとより効率的なスクリプトの実行によって進化すると、これらの制限は変更されることになります。

これらのページで提供されるデータは、Hydraの[統合プロセス](https://github.com/input-output-hk/hydra-poc/actions/workflows/ci.yaml)によって生成されるため、コードの現在の状態を反映することが保証されています。

```mdx-code-block
import DocCardList from '@theme/DocCardList';
import {useDocsSidebar} from '@docusaurus/theme-common';

<DocCardList items={useDocsSidebar().filter(({ docId }) => docId != "index")}/>
```
