{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko = {
      url = "github:nix-community/disko";
    };
    fedimint = {
      # CHANGEME: change to a version you'd like to use
      # url = "github:fedimint/fedimint?ref=refs/tags/v0.3.1";
      url = "github:fedimint/fedimint?rev=d2840ae5d9988eed601f9bc917d4f2028c7bcee9";
    };
    fedimint-ui = {
      url = "github:fedimint/ui?rev=b57151db3bc4afa373cd61d67b8677e0ba38ceeb";
    };
    nix-bitcoin = {
      url = "github:fort-nix/nix-bitcoin/release";
    };
  };

  outputs = { nixpkgs, disko, fedimint, fedimint-ui, nix-bitcoin, ... }:

    let

      overlays = [
        (final: prev: {
          fedimintd = fedimint.packages.${final.system}.fedimintd;
          fedimint-cli = fedimint.packages.${final.system}.fedimint-cli;
          fedimint-ui = fedimint-ui.packages.${final.system}.guardian-ui;
        })
      ];

      topLevelModule = {
        nixpkgs = {
          inherit overlays;
        };
        nix = {
          registry = {
            nixpkgs.flake = nixpkgs;
          };
          nixPath = [ "nixpkgs=${nixpkgs}" ];
        };
      };

    in
    {
      nixosConfigurations.myfedimint = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          topLevelModule
          nix-bitcoin.nixosModules.default
          fedimint.nixosModules.fedimintd

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

