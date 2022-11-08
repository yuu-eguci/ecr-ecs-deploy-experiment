ECR + ECS deploy experiment
===

この実験をするための手順。

## Dockerfile を作る

## ローカル環境で、 Dockerfile をテストする

```bash
docker build -t ecr-ecs-deploy-experiment-image . && docker run -p 8080:80 ecr-ecs-deploy-experiment-image
```

## aws.yml を取得する

これ↓を commit すればいい。

https://github.com/yuu-eguci/ecr-ecs-deploy-experiment/actions/new?category=none&query=aws+ecs

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
- ECS_CLUSTER: ecr-ecs-deploy-experiment-cluster

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
