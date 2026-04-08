FROM golang:1.24-alpine AS hugo-builder
RUN apk add --no-cache git
RUN go install github.com/gohugoio/hugo@v0.146.0

FROM hugo-builder AS builder
WORKDIR /src
COPY . .
RUN hugo --minify

FROM nginx:alpine
COPY --from=builder /src/public /usr/share/nginx/html
EXPOSE 80
