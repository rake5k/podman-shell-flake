{
  description = "Podman Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, nixpkgs, pre-commit-hooks }:
    let
      name = "podman-shell";

      podman-shell = import ./default.nix;

      overlay = final: prev: {
        ${name} = final.callPackage podman-shell { };
      };

      # System types to support.
      supportedSystems = [ "aarch64-linux" "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [ overlay ];
      });
    in
    {

      apps = forAllSystems (system: {
        ${name} = {
          type = "app";
          program = "${self.packages.${system}.${name}}/bin/podman";
        };
        default = self.apps.${system}.${name};
      });

      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          ${name} = pkgs.callPackage podman-shell { };
          default = self.packages.${system}.${name};
        });

      overlays.default = final: prev: {
        ${name} = self.packages.${prev.system}.default;
      };

      checks = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          build = self.packages.${system}.${name};

          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixpkgs-fmt.enable = true;
              statix.enable = true;
            };
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            inherit name;

            buildInputs = with pkgs; [
              # banner printing on enter
              figlet
              lolcat

              nixpkgs-fmt
              statix

              self.packages.${system}.${name}
              self.packages.${system}.${name}.dockerCompat
            ];

            shellHook = ''
              figlet ${name} | lolcat --freq 0.5
              ${self.checks.${system}.pre-commit-check.shellHook}
              ${self.packages.${system}.${name}.shellHook}
            '';
          };
        });
    };
}
