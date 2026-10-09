FROM golang:1.27-alpine AS build

WORKDIR /src
COPY go.mod ./
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/ostrovok-api ./cmd/api

FROM alpine:3.22

RUN addgroup -S ostrovok && adduser -S ostrovok -G ostrovok
WORKDIR /app
COPY --from=build /out/ostrovok-api /usr/local/bin/ostrovok-api
COPY static /app/static

USER ostrovok
EXPOSE 8080
ENV PORT=8080

HEALTHCHECK --interval=15s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["ostrovok-api"]
