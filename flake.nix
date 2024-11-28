{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = inputs@{ self, colmena, nixpkgs, ... }:
  {
    # https://github.com/zhaofengli/colmena/pull/228
    colmenaHive = colmena.lib.makeHive self.outputs.colmena;
    colmena = {  
      meta = {
        # need to pin nixpkgs for colmena
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
        # we need access to the inputs
        specialArgs = {
          inherit inputs;
        };
      };

      defaults = {
        # all deployments happen on the PSA server
        deployment.targetHost = "psa.in.tum.de";
      };

      "vmpsateam06-01" = {
        # ssh port
        deployment.targetPort = 60601;

        # import configuration
        imports = [
          { networking.hostName = "vmpsateam06-01"; }
          ./configuration.nix
        ];
      };
    };
  };
}
