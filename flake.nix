{
  inputs = {
  	nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  	unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ nixpkgs, ... }:
  {
  	nixosConfigurations = {
      "vmpsateam06-01" = nixpkgs.lib.nixosSystem {
      	system = "x86_64-linux";
      	specialArgs = {
      		inherit inputs;
      	};
      	modules = [
      	  { networking.hostName = "vmpsateam06-01"; }
      	  ./configuration.nix
      	];
      };
  	};
  };
}
