{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        
        darwinDeps = with pkgs; if stdenv.hostPlatform.isDarwin then [
          darwin.apple_sdk_11_0.frameworks.Accelerate
          darwin.apple_sdk_11_0.frameworks.MetalKit
        ] else [];
      in
      {
        devShells.default = pkgs.mkShell {
          shellHook = ''
            # Setup the virtual environment if it doesn't already exist.
            VENV=.venv
            if test ! -d $VENV; then
              virtualenv $VENV
            fi
            source ./$VENV/bin/activate
            export PYTHONPATH=`pwd`/$VENV/${pkgs.python3.sitePackages}/:$PYTHONPATH
            CMAKE_ARGS="-DLLAMA_METAL=on -DCMAKE_C_FLAGS=-D__ARM_FEATURE_DOTPROD=1" FORCE_CMAKE=1 pip install --upgrade --force-reinstall -r requirements.txt --no-cache-dir
          '';

          buildInputs = with pkgs; [
            # Select nix environment
            nix-direnv

            # Nix
            rnix-lsp
            nixpkgs-fmt

            # Build deps
            cmake

            # Python
            (python3.withPackages (ps: with ps; [
              pip
              virtualenv
            ]))
          ] ++ darwinDeps;
        };
      });
}
