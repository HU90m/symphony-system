{
  description = "Symphony System";
  inputs = {
    lowrisc-nix.url = "/home/hugom/repo/lr/lowrisc-nix";
    nixpkgs.follows = "lowrisc-nix/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    lowrisc-nix,
  }: let
    system_outputs = system: let
      version = "0.1.0";
      pkgs = import nixpkgs {inherit system;};
      fs = pkgs.lib.fileset;
      lib_doc = lowrisc-nix.lib.doc {inherit pkgs;};

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

      docs_build = lib_doc.buildMdbookSite {
        inherit version;
        pname = "symphony-system-documentation";
        nativeBuildInputs = [pkgs.python311];
        src = fs.toSource {
          root = ./.;
          fileset = fs.unions [
            (lib_doc.standardMdbookFileset ./.)
            ./util/mdbook
            ./util/mdbook_wavejson.py
          ];
        };
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
