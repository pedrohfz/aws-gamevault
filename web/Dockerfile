FROM golang:1.24-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o gamevault-web .

FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/gamevault-web .
COPY --from=builder /app/templates ./templates
COPY --from=builder /app/static ./static

EXPOSE 3000

CMD ["./gamevault-web"]
