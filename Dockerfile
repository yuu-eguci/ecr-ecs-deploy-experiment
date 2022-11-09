# https://hub.docker.com/_/nginx
FROM nginx:mainline-alpine

# 本番環境用の Dockerfile なので、ソースを image 内へコピー。
COPY ./html /usr/share/nginx/html
