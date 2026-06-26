## 開発方法

### 必要なもの

- Node.js v22.14.0 以上

### セットアップ

1. pnpm （パッケージマネージャ）を有効化します
   - ```bash
     corepack enable pnpm
     corepack use pnpm@latest
     ```
2. 依存パッケージをインストールします
   - ```bash
     pnpm install
     ```

### ビルド・起動

1. サーバーを起動します
   - ```bash
     pnpm run start
     ```
2. AremaTV Web アプリには `http://localhost:8000/` でアクセスします

## ディレクトリ構成

pnpm workspaces を採用しています。

- `/workspaces/server` : サーバーの実装です
- `/workspaces/client` : AremaTV Web アプリの実装です
- `/workspaces/schema` : データベースモデルと API リクエスト・レスポンスのインタフェースです
- `/workspaces/configs`: Node.js 関連エコシステムの設定ファイル群です
- `/workspaces/test`: E2E テストと VRT の実行環境です

## API ドキュメント

API ドキュメントを Swagger UI で提供しています。

ローカルでサーバーを建てて、 `http://localhost:8000/api/docs` にアクセスします。

## Visual Regression Test

Playwright で Visual Regression Test (VRT) を提供しています。

競技後のレギュレーションチェックでは、 [./test_cases.md](./test_cases.md) 記載の手動テストに加え、VRT の結果も検証します。

### 使い方

1. Playwright 用の Chromium をインストールします
   - ```bash
     pnpm --filter "@wsh-2025/test" exec playwright install chromium
     ```
2. ローカル環境に対してテストを実行する場合は、サーバーをあらかじめ起動しておきます
   - ```bash
     pnpm run build && pnpm run start
     ```
3. VRT を実行します

   - :warning: スクリーンショットは環境によって差異が生じるため、ご自身の環境で最初に取り直すことを推奨します
     - スクリーンショットを取り直す場合は、 `/workspaces/test/package.json` のコマンドに `--update-snapshots` オプションを追加します
   - ローカル環境に対してテストを実行する場合
     - ```bash
       pnpm run test
       ```
   - リモート環境に対してテストを実行する場合
     - ```bash
       E2E_BASE_URL=https://web-speed-hackathon-2025.example.com pnpm run test
       ```
