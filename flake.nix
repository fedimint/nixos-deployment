{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    disko = {
      url = "github:nix-community/disko";
    };
    nix-bitcoin = {
      url = "github:fort-nix/nix-bitcoin/release";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      disko,
      nix-bitcoin,
      ...
    }:
    let
      topLevelModule = {
        nix = {
          registry = {
            nixpkgs.flake = nixpkgs;
          };
          nixPath = [ "nixpkgs=${nixpkgs}" ];
        };
      };

    in
    {
      nixosConfigurations = {
        myfedimint = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            topLevelModule
            nix-bitcoin.nixosModules.default

            disko.nixosModules.disko
            # CHANGEME: `/dev/vda` is a typically a disk name on VPSes.
            # Sometimes `/dev/sda`
            # `/dev/nvme0n1` is often used on bare-metal servers. You can
            # use `df` on the server to verify.
            # Needs to be a whole disk device, not just a partition.
            { disko.devices.disk.disk1.device = "/dev/vda"; }
            ./configuration.nix
          ];
        };
      };
    }
    //
      flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          devShells = {
            default = pkgs.mkShell {
              packages = [
                pkgs.just
              ];
            };
          };
        }
      )
  ;
}
