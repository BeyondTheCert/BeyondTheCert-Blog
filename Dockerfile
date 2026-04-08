FROM hugomods/hugo:exts-0.146.0 as builder
WORKDIR /src
COPY . .
RUN hugo --minify

FROM nginx:alpine
COPY --from=builder /src/public /usr/share/nginx/html
EXPOSE 80
