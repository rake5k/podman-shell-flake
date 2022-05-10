{ podman
, runc
, conmon
, skopeo
, slirp4netns
, fuse-overlayfs
, writeText
, writeScript
, runtimeShell
, runCommandNoCC
}:

let

  # To use this shell.nix on NixOS your user needs to be configured as such:
  # users.extraUsers.adisbladis = {
  #   subUidRanges = [{ startUid = 100000; count = 65536; }];
  #   subGidRanges = [{ startGid = 100000; count = 65536; }];
  # };

  # Provides a script that copies required files to ~/
  setupScript =
    let
      registriesConf = writeText "registries.conf" ''
        [registries.search]
        registries = ['docker.io']
        [registries.block]
        registries = []
      '';
    in
    writeScript "podman-setup" ''
      #!${runtimeShell}
      # Dont overwrite customised configuration
      if ! test -f ~/.config/containers/policy.json; then
        install -Dm555 ${skopeo.src}/default-policy.json ~/.config/containers/policy.json
      fi
      if ! test -f ~/.config/containers/registries.conf; then
        install -Dm555 ${registriesConf} ~/.config/containers/registries.conf
      fi
    '';

  # Provides a fake "docker" binary mapping to podman
  dockerCompat = runCommandNoCC "docker-podman-compat" { } ''
    mkdir -p $out/bin
    ln -s ${podman}/bin/podman $out/bin/docker
  '';

in

podman.overrideAttrs (attrs: {

  inherit dockerCompat;

  buildInputs = [
    podman # Docker compat
    runc # Container runtime
    conmon # Container runtime monitor
    skopeo # Interact with container registry
    slirp4netns # User-mode networking for unprivileged namespaces
    fuse-overlayfs # CoW for images, much faster than default vfs
  ];

  shellHook = setupScript;

})
