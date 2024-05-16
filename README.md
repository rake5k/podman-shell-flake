# Podman Nix Development Shell Flake

[![NixOS][nixos-badge]][nixos]
[![Build and Test][ci-badge]][ci]
[![Update][update-badge]][update]

This flake should enable you to inject podman as a development environment dependency.

## Usage

For providing the `podman-shell` in a Nix development shell, this flake needs to be added to the
`inputs` and its `overlay` registered in the `pkgs` overlay. Afterwards it can just be added to the
`buildInputs` - but don't forget to integrate its `shellHook` as well.

**Example**

```nix
# flake.nix

{
  description = "Podman shell flake demo";

  inputs.podman-shell.url = "github:rake5k/podman-shell-flake";

  outputs = { self, nixpkgs, podman-shell }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          podman-shell.overlay
        ];
      };
    in
    {
      devShell = pkgs.mkShell {
        name = "my-dev-shell";

        buildInputs = with pkgs; [
          podman-shell
          podman-shell.dockerCompat # optional - for use as a `docker` drop-in replacement
        ];

        inherit (pkgs.podman-shell) shellHook;
      };
    };
}
```

## References

Highly inspired by [adisbladis' podman-shell.nix](https://gist.github.com/adisbladis/187204cb772800489ee3dac4acdd9947).

[nixos]: https://nixos.org/
[nixos-badge]: https://img.shields.io/badge/NixOS-blue.svg?logo=NixOS&logoColor=white
[ci]: https://github.com/rake5k/podman-shell-flake/actions/workflows/ci.yml
[ci-badge]: https://github.com/rake5k/podman-shell-flake/actions/workflows/ci.yml/badge.svg
[update]: https://github.com/rake5k/podman-shell-flake/actions/workflows/update.yml
[update-badge]: https://github.com/rake5k/podman-shell-flake/actions/workflows/update.yml/badge.svg

