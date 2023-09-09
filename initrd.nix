{ config, pkgs, modulesPath, ... }:

{
  imports =
    [ 
      # Modules...
      (modulesPath + "/profiles/qemu-guest.nix")
    ];

  boot.initrd.availableKernelModules = [ "ata_piix" "virtio_pci" "floppy" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ "virtio_dma_buf" "virtio_gpu" "virtio_console" "drm_kms_helper" "drm" "serio" "serio_raw" "atkbd" "psmouse" "i8042" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams = [ "nomodeset" "verbose" ];
  boot.extraModulePackages = [ ];
  swapDevices = [ ];
  nixpkgs.hostPlatform = "x86_64-linux";
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
  # boot.initrd.extraUtilsCommands = "";
  boot.initrd.extraFiles = {
    "/etc/nix/nix.conf" = {
      "source" = pkgs.writeTextFile {
        name = "nixconf";
	text = ''
	  experimental-features = nix-command flakes
	  build-users-group =
	  sandbox = false
	'';
      };
    };
    "/etc/passwd" = {
      "source" = pkgs.writeTextFile {
        name = "initpasswd";
	text = ''
	  root:x:0:0:root:/tmp:/bin/ash
	'';
      };
    };
    "/etc/group" = {
      "source" = pkgs.writeTextFile {
        name = "initgroup";
	text = ''
	  root:x:0:
	'';
      };
    };
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
  boot.initrd.postMountCommands = ''
    echo "target root $targetRoot"
    echo "stage2init $stage2Init"
    mount -o remount,size=2G /
    mount --bind / /
    /tools/nix/bin/nix build --no-write-lock-file github:noblepayne/nix-playground#nixosConfigurations.testsystem.config.system.build.toplevel -o /tmp/toplevel
    cp /tmp/toplevel/init /tmp/init
    mkdir -p /mnt-root/nix/store
    # cp /tmp/toplevel/init /mnt-root/init
    # TODO: copy rather than move? more memory pressure
    # TODO: use --store?
    /tools/nix/bin/nix path-info -r /tmp/toplevel | while IFS= read -r filename; do echo $filename; mv $filename /mnt-root/nix/store; done
    # mount --bind /nix /mnt-root/nix
  '';
}
