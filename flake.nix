{
  description = "a whole big mess o' nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      "initrd" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./initrd.nix
        ];
      };
      "testsystem" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./testsystem.nix
        ];
      };

    };
  };
}
