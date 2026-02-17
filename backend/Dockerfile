FROM golang:1.25-alpine

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . .

RUN go build -o server ./cmd/server

RUN mkdir -p /app/uploads/profile_photo /app/uploads/id_card

EXPOSE 8080

CMD ["./server"]
