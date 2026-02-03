.PHONY: help build test test-verbose clean

help:
	@echo "Available targets:"
	@echo "  make build         - Build WASM plugin"
	@echo "  make test          - Run tests"
	@echo "  make test-verbose  - Run tests with coverage"
	@echo "  make clean         - Remove build artifacts"

build:
	@echo "Building WASM plugin..."
	GOOS=wasip1 GOARCH=wasm go build -o plugin.wasm main.go
	@echo "Build complete: plugin.wasm"
	@ls -lh plugin.wasm

test:
	go test -v ./pkg/...

test-verbose:
	go test -v -coverprofile=coverage.out ./pkg/...
	go tool cover -func=coverage.out

clean:
	rm -f plugin.wasm coverage.out coverage.html
