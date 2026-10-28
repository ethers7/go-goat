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

# Add ca-certificates in case your application makes external HTTPS requests,
# and create an unprivileged user/group (uid/gid 65532) to run the app
RUN apk --no-cache add ca-certificates \
    && addgroup -g 65532 -S nonroot \
    && adduser -u 65532 -S -G nonroot -H -s /sbin/nologin nonroot

# Set the working directory
WORKDIR /app

# Copy the Pre-built binary file from the previous stage
COPY --from=builder --chown=65532:65532 /app/gogoat .

# Expose HTTP port (>1024, no root privileges required)
EXPOSE 8080

# Run as a non-root user
USER 65532:65532

# Command to run the executable
CMD ["./gogoat"]
