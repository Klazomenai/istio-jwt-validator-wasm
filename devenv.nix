{ pkgs, lib, config, ... }:

{
  # Package versions
  languages.go = {
    enable = true;
    package = pkgs.go_1_25;
  };

  # Development packages
  packages = with pkgs; [
    # Go tooling
    gopls
    gotools
    go-tools
    golangci-lint

    # WASM tooling
    wasmtime

    # GitHub CLI
    gh

    # Testing
    gnumake
  ];

  # Environment variables
  env = {
    GOOS = "wasip1";
    GOARCH = "wasm";
  };

  # Scripts
  scripts = {
    build-wasm.exec = ''
      GOOS=wasip1 GOARCH=wasm go build -o plugin.wasm main.go
      echo "Built: $(ls -lh plugin.wasm)"
    '';

    test.exec = ''
      go test -v -coverprofile=coverage.out ./pkg/...
      go tool cover -func=coverage.out
    '';

    test-coverage.exec = ''
      go test -v -coverprofile=coverage.out ./pkg/...
      go tool cover -html=coverage.out -o coverage.html
      echo "Coverage report: coverage.html"
    '';

    lint.exec = ''
      golangci-lint run ./...
    '';
  };

  # Git hooks
  git-hooks.hooks = {
    gofmt.enable = true;
    govet.enable = true;
  };

  # Processes (for future local testing with services)
  # processes = {
  #   redis.exec = "redis-server --port 6379";
  # };

  # Shell welcome message
  enterShell = ''
    echo ""
    echo "🦀 istio-jwt-validator-wasm devenv"
    echo ""
    echo "Available commands:"
    echo "  build-wasm        - Build WASM plugin (native Go WASM)"
    echo "  test              - Run tests with coverage"
    echo "  test-coverage     - Generate HTML coverage report"
    echo "  lint              - Run golangci-lint"
    echo ""
    go version
    echo ""
  '';
}
