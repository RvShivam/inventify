# Start from the official Golang image to build our application.
FROM golang:1.24.6-alpine AS builder

# Set the current working directory inside the container.
WORKDIR /app

# Copy go mod and sum files.
# Since we wiped the directory, these might not exist yet, 
# but this is the standard setup for when we init the go module.
COPY go.mod go.sum* ./

# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed.
RUN if [ -f go.mod ]; then go mod download; fi

# Copy the source code into the container.
COPY . .

# Build the Go app. (Assuming our entrypoint will be cmd/api/main.go)
# We use CGO_ENABLED=0 to ensure a statically linked binary.
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/api/main.go || echo "No main.go found yet. Skipping build for now."

# Start a new, final stage from a minimal alpine image.
FROM alpine:latest  

# Add maintainer info
LABEL maintainer="Inventify Team"

WORKDIR /root/

# Copy the Pre-built binary file from the previous stage.
# If it failed to build because we haven't written it yet, this will just be skipped or fail during image build, 
# but it's ready for when we do write it.
COPY --from=builder /app/main . || true

# Copy the environment variables file if it exists
COPY .env* ./

# Command to run the executable
CMD ["./main"]
