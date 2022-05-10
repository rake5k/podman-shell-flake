{
  description = "Podman Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix?rev=6799201bec19b753a4ac305a53d34371e497941e";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks }:
    let
      name = "podman-shell";

      podman-shell = import ./default.nix;

      overlay = final: prev: {
        "${name}" = final.callPackage podman-shell { };
      };
    in
    flake-utils.lib.eachSystem
      [ "aarch64-linux" "i686-linux" "x86_64-linux" ]
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        rec {

          apps."${name}" = flake-utils.lib.mkApp { drv = packages."${name}"; };

          defaultApp = apps."${name}";

          packages."${name}" = pkgs.callPackage podman-shell { };

          defaultPackage = packages."${name}";

          checks = {
            build = pkgs."${name}";

            pre-commit-check = pre-commit-hooks.lib."${system}".run {
              src = ./.;
              hooks = {
                nixpkgs-fmt.enable = true;
                statix.enable = true;
              };
            };
          };

          devShell = pkgs.mkShell {
            inherit name;

            buildInputs = with pkgs; [
              # banner printing on enter
              figlet
              lolcat

              nixpkgs-fmt
              statix

              packages."${name}"
              packages."${name}".dockerCompat
            ];

            shellHook = ''
              figlet ${name} | lolcat --freq 0.5
              ${checks.pre-commit-check.shellHook}
              ${packages."${name}".shellHook}
            '';
          };
        }) // {
      inherit overlay;
    };
}
