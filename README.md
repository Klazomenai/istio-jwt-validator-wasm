# istio-jwt-validator-wasm

Envoy WASM plugin for JWT validation endpoint with HttpOnly cookie management.

> **⚠️ Alpha Status**: v0.1.0-alpha - Not production ready.

## Overview

WASM plugin that validates JWT tokens via two-stage authentication:
1. CSRF token validation
2. JWT signature and revocation check

Sets HttpOnly session cookie on successful validation.

## Development Setup

### Using devenv (Recommended)

[devenv](https://devenv.sh) provides a reproducible development environment with Go 1.25, testing tools, and pre-commit hooks.

**Installation**:
```bash
# Install devenv (requires Nix)
# See: https://devenv.sh/getting-started/

# Enter development environment:
devenv shell

# Or use direnv for automatic activation:
direnv allow
```

**Available commands**:
```bash
build-wasm        # Build WASM plugin (native Go WASM)
test              # Run tests with coverage
test-coverage     # Generate HTML coverage report
```

### Manual Setup

**Requirements**: Go 1.25+

```bash
# Install dependencies
go mod download

# Build WASM plugin
make build

# Run tests
make test

# Output: plugin.wasm
```

**Build details**: Uses native Go WASM compiler (`GOOS=wasip1 GOARCH=wasm`), not TinyGo.

## Configuration

```yaml
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: jwt-validator
  namespace: istio-system
spec:
  url: oci://ghcr.io/klazomenai/istio-jwt-validator-wasm:v0.1.0-alpha.0
  pluginConfig:
    cluster: "outbound|8080||jwt-service.namespace.svc.cluster.local"
    validateEndpoint: "/api/validate"
    csrfHeaderName: "X-CSRF-Token"
    cookieName: "session"
    cookieDomain: ".example.com"
```

## License

MIT - see [LICENSE](LICENSE)
