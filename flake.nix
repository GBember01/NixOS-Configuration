{
  description = "GBember's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }: {
    nixosConfigurations = {
      # The hostname "nix-box" must match networking.hostName
      nix-box = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nix-box/configuration.nix
        ];
      };
    };
  };
}
