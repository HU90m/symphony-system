{
  description = "Symphony System";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    system_outputs = system: let
      version = "0.1.0";
      pkgs = import nixpkgs {
        inherit system;
      };
      docs_build = pkgs.stdenv.mkDerivation {
        pname = "symphony-system-documentation";
        version = version;
        src = with pkgs.lib.strings;
          # only include wanted files
          builtins.path {
            path = ./.;
            filter = path: type: (
              type
              == "directory"
              || hasInfix "util/mdbook" path
              || builtins.any (suffix: hasSuffix suffix path) [
                ".md"
                ".svg"
                ".png"
                "book.toml"
              ]
            );
          };
        nativeBuildInputs = [pkgs.mdbook pkgs.tree pkgs.python311];
        phases = ["unpackPhase" "buildPhase" "installPhase"];
        buildPhase = "mdbook build";
        installPhase = ''
          mkdir $out
          mv book/* $out
        '';
      };
      python_check_app = pkgs.writeShellApplication {
        name = "python-check";
        runtimeInputs = with pkgs; [
          ruff
          python311
          python311Packages.mypy
        ];
        text = ''
          ruff format --check .
          ruff check .
          mypy .
        '';
      };
      python_fix_app = pkgs.writeShellApplication {
        name = "python-fix";
        runtimeInputs = [pkgs.ruff];
        text = ''
          ruff format .
          ruff check --fix .
        '';
      };
    in {
      formatter = pkgs.alejandra;
      packages.docs = docs_build;
      apps.python_check = {
        type = "app";
        program = "${python_check_app}/bin/python-check";
      };
      apps.python_fix = {
        type = "app";
        program = "${python_fix_app}/bin/python-fix";
      };
    };
  in
    flake-utils.lib.eachDefaultSystem system_outputs;
}
