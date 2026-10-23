# https://hub.docker.com/_/nginx
FROM nginx:1.31-alpine

# 本番環境用の Dockerfile なので、ソースを image 内へコピー。
COPY ./html /usr/share/nginx/html
