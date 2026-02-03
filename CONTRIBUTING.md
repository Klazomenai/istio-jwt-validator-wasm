# Contributing to istio-jwt-validator-wasm

Thank you for your interest in contributing! This document provides guidelines for development and submitting changes.

## Development Setup

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [devenv](https://devenv.sh/getting-started/) (recommended)
- Git

### Quick Start

```bash
# Clone the repository
git clone https://github.com/Klazomenai/istio-jwt-validator-wasm.git
cd istio-jwt-validator-wasm

# Enter development environment
devenv shell

# Run tests
test

# Build WASM plugin
build-wasm

# Run linters
lint
```

### Development Tools

The devenv environment provides:
- Go 1.25
- golangci-lint (15+ linters)
- wasmtime (WASM runtime)
- Pre-commit hooks (gofmt, govet)

## Code Style

### Go Conventions

- Follow standard Go conventions ([Effective Go](https://go.dev/doc/effective_go))
- Use `gofmt` for formatting (enforced by pre-commit hooks)
- Run `golangci-lint` before committing (7 enabled linters)

### Enabled Linters

```yaml
- errcheck      # Check for unchecked errors
- govet         # Go vet analysis
- staticcheck   # Static analysis
- unused        # Detect unused code
- misspell      # Spelling errors
- gosec         # Security issues
- ineffassign   # Ineffectual assignments
```

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (dependencies, CI, etc.)
- `perf`: Performance improvements
- `ci`: CI/CD changes

### Examples

```
feat(jwt): add token expiry validation

fix(csrf): handle missing CSRF token gracefully

docs: update installation instructions

chore(deps): update proxy-wasm-go-sdk to v0.2.0
```

## Pull Request Process

### Before Submitting

1. **Run tests**: `test` (all tests must pass)
2. **Run linters**: `lint` (no linting errors)
3. **Check coverage**: Ensure coverage stays above 70%
4. **Update docs**: If adding features, update README.md

### Submitting a PR

1. **Fork and branch**: Create a feature branch from `main`
   ```bash
   git checkout -b feat/my-feature
   ```

2. **Make changes**: Commit with conventional commit messages

3. **Push and create PR**: Push to your fork and create a PR
   ```bash
   git push origin feat/my-feature
   gh pr create --draft  # Create draft PR
   ```

4. **CI checks**: All CI checks must pass:
   - ✓ Lint (gofmt, go vet, golangci-lint)
   - ✓ Security (gosec, govulncheck)
   - ✓ Test (unit tests, race detection, 70% coverage)
   - ✓ Build (WASM artifact)

5. **Review**: Mark PR as ready for review when CI passes

6. **Merge**: Squash and merge when approved

### PR Title

Use conventional commit format for PR titles:
```
feat(jwt): add token expiry validation
```

## Testing

### Writing Tests

- Place tests in `*_test.go` files
- Use table-driven tests where appropriate
- Test coverage should be ≥70% (enforced by CI)

### Running Tests

```bash
# Run all tests
test

# Run tests with race detection
devenv shell -- go test -race ./...

# Generate coverage report
test-coverage
# Opens coverage.html in browser
```

### Test Structure

```go
func TestMyFunction(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    string
        wantErr bool
    }{
        {
            name:  "valid input",
            input: "test",
            want:  "result",
        },
        // ...
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := MyFunction(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("got error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if got != tt.want {
                t.Errorf("got %v, want %v", got, tt.want)
            }
        })
    }
}
```

## Security

### Security Scanning

CI runs two security tools:
- **gosec**: Scans code for security anti-patterns
- **govulncheck**: Checks dependencies for known CVEs

### Reporting Security Issues

Please report security vulnerabilities privately via GitHub Security Advisories:
https://github.com/Klazomenai/istio-jwt-validator-wasm/security/advisories/new

Do not open public issues for security vulnerabilities.

## Building and Releasing

### Local Builds

```bash
# Build with devenv (development)
build-wasm

# Build with Nix (reproducible)
nix build .#wasm
# Output: result/plugin.wasm

# Build OCI image
nix build .#oci-image
```

### Releases

Releases are automated via GitHub Actions:

1. **Create tag**: `git tag v0.1.0-alpha.2 && git push origin v0.1.0-alpha.2`
2. **CI builds**: WASM + OCI image with pure Nix
3. **Publishes**:
   - GitHub Release with WASM binary
   - OCI image to `ghcr.io/klazomenai/istio-jwt-validator-wasm:v0.1.0-alpha.2`

### Versioning

Follow [Semantic Versioning](https://semver.org/):
- `v0.x.x-alpha.y` - Alpha releases (current)
- `v0.x.x-beta.y` - Beta releases (future)
- `v0.x.x` - Stable releases (future)

## Questions?

- Open a [discussion](https://github.com/Klazomenai/istio-jwt-validator-wasm/discussions)
- Open an [issue](https://github.com/Klazomenai/istio-jwt-validator-wasm/issues)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
