{
  description = "JWT Validator WASM Plugin for Istio";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Extract version from git or use default
        version = if (builtins.pathExists ./.git)
          then builtins.readFile (pkgs.runCommand "get-version" {} ''
            cd ${./.}
            ${pkgs.git}/bin/git describe --tags --always --dirty 2>/dev/null > $out || echo "0.1.0-dev" > $out
          '')
          else "0.1.0-dev";

      in {
        packages = {
          # Pure Nix WASM build
          wasm = pkgs.buildGoModule {
            pname = "istio-jwt-validator-wasm";
            inherit version;
            src = ./.;

            # This will need to be updated when dependencies change
            # Run: nix build .#wasm 2>&1 | grep "got:" to get the correct hash
            vendorHash = "sha256-6B0OTDdCSdAnj3u1i8ZvQNVGs8tChAP6EDk2pv2iX5c=";

            buildPhase = ''
              export GOOS=wasip1
              export GOARCH=wasm
              go build -o plugin.wasm main.go
            '';

            installPhase = ''
              mkdir -p $out
              cp plugin.wasm $out/plugin.wasm
            '';

            meta = with pkgs.lib; {
              description = "JWT Validator WASM Plugin for Istio";
              homepage = "https://github.com/klazomenai/istio-jwt-validator-wasm";
              license = licenses.mit;
              platforms = platforms.all;
            };
          };

          # OCI image with WASM plugin
          oci-image = pkgs.dockerTools.buildLayeredImage {
            name = "ghcr.io/klazomenai/istio-jwt-validator-wasm";
            tag = builtins.replaceStrings ["\n"] [""] version;

            contents = [ pkgs.cacert ];

            config = {
              Cmd = [ "${pkgs.bash}/bin/bash" ];
              Labels = {
                "org.opencontainers.image.source" = "https://github.com/klazomenai/istio-jwt-validator-wasm";
                "org.opencontainers.image.description" = "JWT Validator WASM Plugin for Istio";
                "org.opencontainers.image.version" = builtins.replaceStrings ["\n"] [""] version;
                "org.opencontainers.image.vendor" = "Klazomenai";
                "org.opencontainers.image.licenses" = "MIT";
              };
            };

            extraCommands = ''
              mkdir -p plugin
              # Copy from pure Nix build - fully reproducible!
              cp ${self.packages.${system}.wasm}/plugin.wasm plugin/plugin.wasm
            '';
          };

          # Default package
          default = self.packages.${system}.wasm;
        };

        # Development shell (optional - devenv is primary)
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            go_1_25
            gopls
            gotools
            go-tools
            golangci-lint
            wasmtime
            gh
          ];

          shellHook = ''
            echo "🔨 Nix development shell"
            echo "Note: Use 'devenv shell' for full devenv experience"
            echo ""
            echo "Available commands:"
            echo "  nix build .#wasm       - Build WASM (reproducible)"
            echo "  nix build .#oci-image  - Build OCI image (reproducible)"
            echo ""
          '';
        };

        # Apps for convenience
        apps = {
          # Build WASM
          build-wasm = {
            type = "app";
            program = "${pkgs.writeShellScript "build-wasm" ''
              ${pkgs.nix}/bin/nix build .#wasm
              cp result/plugin.wasm plugin.wasm
              ls -lh plugin.wasm
            ''}";
          };

          # Build OCI image
          build-oci = {
            type = "app";
            program = "${pkgs.writeShellScript "build-oci" ''
              ${pkgs.nix}/bin/nix build .#oci-image
              echo "OCI image built: result"
            ''}";
          };
        };
      }
    );
}
