{
  description = "Nix packaging for cyan-skillfish-governor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      perSystem = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          packages.default = pkgs.rustPlatform.buildRustPackage rec {
            pname = "cyan-skillfish-governor";
            version = "0.1.3";

            src = pkgs.fetchFromGitHub {
              owner = "Magnap";
              repo = "cyan-skillfish-governor";
              rev = "v${version}";
              hash = "sha256-EJhgk3ixZvLsZ9rbQ7LDJtx3K8K/qEraDwBrkOtHPuk=";
            };

            cargoLock = {
              lockFile = ./Cargo.lock;
            };

            nativeBuildInputs = with pkgs; [ pkg-config ];
            buildInputs = with pkgs; [ libdrm ];

            postInstall = ''
              install -Dm444 default-config.toml $out/share/cyan-skillfish-governor/default-config.toml
              install -Dm444 cyan-skillfish-governor.service $out/lib/systemd/system/cyan-skillfish-governor.service
            '';

            meta = with pkgs.lib; {
              description = "GPU governor for the AMD Cyan Skillfish APU";
              homepage = "https://github.com/Magnap/cyan-skillfish-governor";
              license = licenses.mit;
              platforms = platforms.linux;
              mainProgram = "cyan-skillfish-governor";
            };
          };

          devShells.default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.default ];
            packages = with pkgs; [ rustc cargo ];
          };
        });
    in
      perSystem // {
        # Wrapper module that defaults `package` to this flake's package, so
        # consumers only need `services.cyan-skillfish-governor.enable = true;`
        # (no `_module.args.self` plumbing required).
        nixosModules.default = { pkgs, lib, ... }: {
          imports = [ ./nixos-module.nix ];
          services.cyan-skillfish-governor.package =
            lib.mkDefault self.packages.${pkgs.system}.default;
        };
      };
}
