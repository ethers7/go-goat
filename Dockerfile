FROM golang:1.15 AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod ./
COPY go.sum ./

# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download

# Copy the source code into the container
COPY . .

# Build the Go app
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gogoat .

# Start a new stage from scratch for the runtime
FROM alpine:latest  

# Add ca-certificates in case your application makes external HTTPS requests
# and create an unprivileged user to run the application
RUN apk --no-cache add ca-certificates \
    && addgroup -S -g 10001 app \
    && adduser -S -u 10001 -G app -h /app app

# Set the working directory
WORKDIR /app

# Copy the Pre-built binary file from the previous stage
COPY --from=builder --chown=10001:10001 /app/gogoat .

# Run as the unprivileged user (numeric UID so runAsNonRoot can be verified)
USER 10001:10001

# Expose HTTP port (unprivileged port, no root needed)
EXPOSE 8080

# Command to run the executable
CMD ["./gogoat"]
