{
  description = "tweakcc";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in { default = self.lib.makePackage pkgs; });

    devShells = forAllSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in { default = self.lib.makeDevShell pkgs; });

    lib.makePackage = pkgs: pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "tweakcc";
    version = "4.0.13";

    src = pkgs.fetchFromGitHub {
      owner = "Piebald-AI";
      repo = "tweakcc";
      rev = "44a7d5535584b3d2a687cb512a2e624ab1ab35e5";
      hash = "sha256-bD5vBTjYswW5BF6Bdt7SHMkOMrMu4yI9MgcpajkZDcE=";
    };

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      fetcherVersion = 3;
      hash = "sha256-jyu65fewiQCvCe0QImlslvgpJew/ZOJ5lqwxUdU3U24=";
    };

    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.pnpm
      pkgs.pnpmConfigHook
      pkgs.makeWrapper
    ];

    buildPhase = ''
      runHook preBuild
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/tweakcc
      cp -r --no-preserve=mode,ownership node_modules $out/lib/tweakcc/node_modules
      cp -r dist $out/lib/tweakcc/
      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/tweakcc \
        --add-flags "$out/lib/tweakcc/dist/index.mjs"
      runHook postInstall
    '';
    });

    lib.makeDevShell = pkgs: pkgs.mkShell {
      packages = [
        pkgs.nodejs
        pkgs.pnpm
      ];
      shellHook = ''
        export TWEAKCC_CC_INSTALLATION_PATH="$PWD/node_modules/.bin/claude"
        export TWEAKCC_CONFIG_DIR="$PWD"
      '';
    };
  };
}

