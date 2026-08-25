{
  description = "Rego / conftest hands-on devShell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "terraform" ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.terraform
            pkgs.conftest
            # nixpkgs-unstable の 1.16.2 は checkPhase が失敗するためテストをスキップする
            (pkgs.open-policy-agent.overrideAttrs (_: {
              doCheck = false;
            }))
          ];
        };
      }
    );
}
