# パフォーマンス研修 運営ガイド

## 概要

このドキュメントは、Web Speed Hackathon 2025 をベースにしたパフォーマンスチューニング研修の運営手順を説明します。

参加者がそれぞれforkしたリポジトリでチューニング作業を行い、pushするだけで自動的にAWS環境にデプロイされ、Lighthouseによるパフォーマンス計測が実行されます。全参加者のスコアはリアルタイムでダッシュボードに反映されます。

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│  参加者の GitHub Fork                                         │
│  ┌──────────┐    push     ┌──────────────────────────────┐  │
│  │  Code    │ ──────────► │  GitHub Actions              │  │
│  └──────────┘             │  1. Docker Build → ECR       │  │
│                           │  2. Deploy → ECS Fargate     │  │
│                           │  3. Lighthouse測定           │  │
│                           │  4. スコア → S3              │  │
│                           └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────┐
│  AWS Infrastructure                                          │
│                                                              │
│  CloudFront ─► ALB ─► ECS Fargate (参加者ごとのサービス)      │
│                                                              │
│  S3 (スコア保存) ─► CloudFront ─► Dashboard (静的サイト)     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## セットアップ手順 (運営者向け)

### 1. 前提条件

- AWS アカウント (適切なIAM権限)
- ドメイン名 (例: `performance-hackathon.your-domain.com`)
- ACM 証明書 (us-east-1 リージョンに作成、ワイルドカード `*.performance-hackathon.your-domain.com`)
- AWS CLI がインストール・設定済み

### 2. インフラストラクチャのデプロイ

```bash
cd infra/scripts

# 環境変数を設定
export AWS_REGION=ap-northeast-1
export DOMAIN_NAME="performance-hackathon.your-domain.com"
export CERTIFICATE_ARN="arn:aws:acm:us-east-1:123456789012:certificate/xxxxx"

# ベースインフラをデプロイ
./setup.sh
```

これにより以下が作成されます：
- VPC + サブネット
- ECS Cluster
- ECR Repository
- ALB (Application Load Balancer)
- CloudFront Distribution (アプリ用 + ダッシュボード用)
- S3 Bucket (スコア保存 + ダッシュボード)
- IAM Roles (GitHub Actions OIDC, ECS)

### 3. DNS 設定

ドメインのDNSに以下を設定：
- `*.performance-hackathon.your-domain.com` → CloudFront Distribution の CNAME
- `dashboard.performance-hackathon.your-domain.com` → Dashboard CloudFront の CNAME

### 4. 参加者の登録

各参加者について、ターゲットグループとリスナールールを作成：

```bash
# 参加者を追加 (GitHub ユーザー名, 優先度番号)
./add-participant.sh alice 10
./add-participant.sh bob 20
./add-participant.sh charlie 30
```

### 5. 参加者リポジトリの設定

各参加者のforkリポジトリに以下のGitHub Secretsを設定：

| Secret名 | 値 |
|-----------|-----|
| `AWS_ROLE_ARN` | setup.sh 出力の GitHubActionsRoleArn |
| `ECS_EXECUTION_ROLE_ARN` | setup.sh 出力の ECSExecutionRoleArn |
| `ECS_TASK_ROLE_ARN` | setup.sh 出力の ECSTaskRoleArn |
| `CLOUDFRONT_DISTRIBUTION_ID` | setup.sh 出力の CloudFrontDistributionId |
| `SUBNET_IDS` | setup.sh 出力の SubnetIds (カンマ区切り) |
| `SECURITY_GROUP_ID` | setup.sh 出力の SecurityGroupId |
| `TARGET_GROUP_ARN_PREFIX` | add-participant.sh で作成されたターゲットグループARN |
| `DOMAIN_NAME` | 参加者環境のベースドメイン (例: `performance-hackathon.your-domain.com`) |

> **Tip**: GitHub Organization を使う場合、Organization レベルで共通の Secrets を設定し、`TARGET_GROUP_ARN_PREFIX` だけリポジトリレベルで設定するのが効率的です。

### 6. ダッシュボードのデプロイ

```bash
# GitHub Actions の "Deploy Dashboard" ワークフローを実行
# もしくは手動で:
aws s3 sync dashboard/ s3://performance-hackathon-dashboard/ --delete
```

## 参加者向け手順

### 1. リポジトリのフォーク

1. 指定されたリポジトリを自分のGitHubアカウントにフォーク
2. 運営からGitHub Secretsが設定されていることを確認

### 2. 開発環境のセットアップ

```bash
git clone https://github.com/<your-username>/performance-hackathon.git
cd performance-hackathon

corepack enable pnpm
pnpm install
pnpm run start
# http://localhost:8000/ でアクセス
```

### 3. チューニング作業

パフォーマンス改善のアプローチ例：
- Webpack の mode を `production` に変更
- ソースマップを `hidden-source-map` または無効化
- コード分割を有効化 (LimitChunkCountPlugin を削除)
- 画像の最適化 (WebP/AVIF変換、適切なサイズ)
- 不要なライブラリの削除/軽量化
- キャッシュヘッダーの設定
- Critical CSS の抽出
- 遅延読み込みの実装

### 4. デプロイ & 計測

```bash
git add .
git commit -m "perf: optimize webpack configuration"
git push origin main
```

pushすると自動的に：
1. Docker イメージがビルドされ ECR にプッシュ
2. ECS Fargate にデプロイ
3. Lighthouse でパフォーマンス計測
4. スコアがダッシュボードに反映

### 5. スコアの確認

- 個人の環境: `https://<your-github-username>.performance-hackathon.your-domain.com`
- ダッシュボード: `https://dashboard.performance-hackathon.your-domain.com`
- GitHub Actions のサマリーでも確認可能

## スコアリング

採点は docs/scoring.md に基づきます。

**ページの表示 (900点満点)**:
- 9ページ × 100点
- 各ページ: FCP×10 + SI×10 + LCP×25 + TBT×30 + CLS×25

## コスト見積もり

| リソース | 概算コスト (10名参加/1日) |
|---------|-------------------------|
| ECS Fargate (0.5vCPU, 1GB × 10) | ~$3-5/日 |
| ALB | ~$0.50/日 |
| CloudFront | ~$1-2/日 |
| ECR | ~$0.50/日 |
| S3 | < $0.10/日 |
| **合計** | **~$5-8/日** |

> **注意**: 研修終了後は必ずリソースを削除してください。

## クリーンアップ

```bash
# ECS サービスを全て削除
aws ecs list-services --cluster performance-hackathon --query 'serviceArns[]' --output text | \
  xargs -n1 aws ecs delete-service --cluster performance-hackathon --force --service

# CloudFormation スタックを削除
aws cloudformation delete-stack --stack-name performance-hackathon-base

# S3 バケットを空にしてから削除 (CloudFormation では空でないバケットは削除できない)
aws s3 rm s3://performance-hackathon-scores --recursive
aws s3 rm s3://performance-hackathon-dashboard --recursive
```

## トラブルシューティング

### デプロイが失敗する
- GitHub Secrets が正しく設定されているか確認
- IAM Role の trust policy に参加者のリポジトリが含まれているか確認

### スコアが計測されない
- ECS サービスが RUNNING 状態か確認
- ターゲットグループのヘルスチェックが通っているか確認
- CloudWatch Logs でアプリケーションログを確認

### ダッシュボードが更新されない
- S3 にスコアファイルがアップロードされているか確認
- CloudFront のキャッシュを手動で無効化してみる
