{ config, pkgs, ... }:

{
  imports =
    [ 
      # Modules...
    ];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=3G" "mode=755" ]; # mode=755 so only root can write to those files
  };
  boot.loader.grub.device = "nodev";


  networking.hostName = "bootie";

  # Enable networking
  # networking.networkmanager.enable = true;
  networking.useDHCP = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  documentation.nixos.enable = false;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  system.stateVersion = "unstable";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.initrd.network.enable = true;
  boot.initrd.extraFiles = {
    "/etc/nix/nix.conf" = {"source" = pkgs.writeTextFile {name = "nixconf"; text = "experimental-features = nix-command flakes";};};
    "/tools/nix" = {"source" = pkgs.stdenv.mkDerivation {
      name = "wrappedNix";
      dontUnpack = true;
      dontBuild = true;
      dontConfigure = true;
      buildInputs = [ pkgs.makeWrapper ];
      installPhase = ''
        mkdir -p $out/bin
        cp -pdv ${pkgs.nix}/bin/nix $out/bin
        wrapProgram $out/bin/nix --set USER "ROOT" --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      '';
    };};
  };
  boot.initrd.postDeviceCommands = ''
    /tools/nix/bin/nix run nixpkgs#hello
  '';
}
