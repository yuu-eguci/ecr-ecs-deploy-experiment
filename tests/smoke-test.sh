#!/usr/bin/env sh
# Smoke test: both the production image (Dockerfile) and the dev container
# (compose.yaml + Dockerfile.dev with ./html mounted) must serve html/index.html as-is.
# Runs locally only; it never talks to AWS.
set -eu

prod_image="ecr-ecs-deploy-experiment-image:smoke"
prod_port="${SMOKE_PROD_PORT:-18080}"

# A separate project name so this never stops your own `docker compose up` session.
smoke_compose() {
  docker compose -p ecr-ecs-deploy-experiment-smoke "$@"
}

cleanup() {
  docker rm -f ecr-ecs-deploy-experiment-smoke >/dev/null 2>&1 || true
  smoke_compose down >/dev/null 2>&1 || true
}
trap cleanup EXIT

expect_index() {
  url="$1"
  i=0
  until curl -fsS "$url" -o /dev/null 2>/dev/null; do
    i=$((i + 1))
    if [ "$i" -ge 30 ]; then
      echo "NG: $url did not respond" >&2
      return 1
    fi
    sleep 1
  done
  curl -fsS "$url" | diff -u html/index.html -
  echo "OK: $url serves html/index.html"
}

docker build -t "$prod_image" .
docker run -d --name ecr-ecs-deploy-experiment-smoke -p "127.0.0.1:$prod_port:80" "$prod_image" >/dev/null
expect_index "http://127.0.0.1:$prod_port/"

smoke_compose up -d --build
expect_index "http://127.0.0.1:8080/"
