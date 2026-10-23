ECR + ECS deploy experiment
===

nginx の静的ページ (`html/`) を ECR に push して、ECS (Fargate) にデプロイする実験。

> [!WARNING]
> デプロイ用の workflow (`.github/workflows/aws.yml`) は手動実行のみ。main に push しても AWS は動かない。
> いまは Actions 画面で workflow 自体も disable してある。デプロイするときは enable してから「Run workflow」する。

この実験をするための手順。

## Dockerfile を作る

- `Dockerfile`: 本番用。`html/` を image にコピーする。ECR に push されるのはこっち。
- `Dockerfile.dev`: 開発用。`html/` はコピーせず、`compose.yaml` でマウントする。

## ローカル環境で、 Dockerfile をテストする

```bash
docker build -t ecr-ecs-deploy-experiment-image . && docker run -p 8080:80 ecr-ecs-deploy-experiment-image
```

`html/` を編集しながら確認したいときは compose を使う。`html/` をマウントしているので、保存してブラウザをリロードすれば反映される。

```bash
docker compose up --build
# http://localhost:8080
```

## テストと lint

Docker (と curl) があれば回せる。PR と main への push では、CI (`.github/workflows/ci.yml`) が同じものを回している。CI は secrets を使わず、image もどこにも push しない。

```bash
# 本番用 image と compose の両方が html/index.html をそのまま返すか (18080 と 8080 番ポートを使う)
tests/smoke-test.sh

# aws.yml が手動実行だけになっているか
docker run --rm -v "$PWD":/w -w /w --entrypoint sh mikefarah/yq:4 tests/deploy-workflow-is-manual.sh

# lint
docker run --rm -i hadolint/hadolint:v2.15.1 < Dockerfile
docker run --rm -i hadolint/hadolint:v2.15.1 < Dockerfile.dev
docker run --rm -v "$PWD":/repo -w /repo rhysd/actionlint:1.7.12
docker run --rm -v "$PWD":/mnt koalaman/shellcheck:stable tests/*.sh
```

## aws.yml を取得する

これ↓を commit すればいい。

https://github.com/yuu-eguci/ecr-ecs-deploy-experiment/actions/new?category=none&query=aws+ecs

ただしテンプレートのままだと main に push するたびにデプロイが走るので、この repo ではトリガーを `workflow_dispatch` (手動実行) に変えてある。

## aws.yml のドキュメントコメントに従って ECR とか ECS をセッティング

### 1. Create an ECR repository to store your images.

このコマンド↓で ECR を作れる。

```bash
aws ecr create-repository --repository-name ecr-ecs-deploy-experiment --region ap-northeast-1
```

以下が手に入る。

- ECR_REPOSITORY: ecr-ecs-deploy-experiment
- AWS_REGION: ap-northeast-1

### 2. Create an ECS task definition, an ECS cluster, and an ECS service.

このページ↓から ECS の cluster + service + task を一気に作れる。ただ……いまのぼくは、何の権限が必要なのか知らない。全権限を持つルートユーザでしか成功していない。

https://ap-northeast-1.console.aws.amazon.com/ecs/home?region=ap-northeast-1#/firstRun

以下が手に入る。

- ECS_SERVICE: experiment-container-service
- ECS_CLUSTER: ecr-ecs-deploy-experiment

### 3. Store your ECS task definition as a JSON file in your repository.

```json
{
  "family": "experiment-container",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "experiment-container",
      "image": "nginx",
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ],
      "essential": true
    }
  ],
  "requiresCompatibilities": [
    "FARGATE"
  ],
  "executionRoleArn": "ecsTaskExecutionRole",
  "cpu": "256",
  "memory": "512"
}
```

- ECS_TASK_DEFINITION: .aws/task-definition.json
- CONTAINER_NAME: experiment-container

### 4. Store an IAM user access key in GitHub Actions secrets named `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

IAM > ユーザー > 該当ユーザー > 認証情報タブ でアクセスキーを作れる

長期間有効なアクセスキーを置いておくより、GitHub の OIDC で IAM ロールを assume する (`role-to-assume`) ほうが安全。

## ローカルでは再現できないもの

ECR、ECS (Fargate)、IAM は AWS 上にしかないので、Docker では再現できない。ローカルで確認できるのは image の build と nginx の動作まで。`.aws/task-definition.json` も、AWS に登録してみるまで正しいかはわからない。

ECS service が動いている間や ECR に image が残っている間は課金が続くので、実験が終わったら消す。
