{
  modulesPath,
  lib,
  pkgs,
  ...
}:

let
  # CHANGEME: register a DNS domain, and make it point at IP of your fedimint server
  # Typically you can use `ip ad ls | grep global` command on the server to find this value.
  fqdn = "nixos-fedimintd-test.dpc.pw";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.helix
    pkgs.tmux
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    # CHANGEME: put your ssh key here
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDRa93v8pzO+EXEH73odhh80VjkLVzPCaRw4K0sObdE9mbZqFB6k791Jm1cVQzHA+sCR4bnyOvA563ExLSGArw4IRxCZvZICSb8RI4QaIhCgf0NtwndKaBxnS2aWrJ/VKNmlZ4OsHMxrFtDRg0AHXBkj0H2O06bJ0+fiwiKdun1tqqi78qQPZkjaJoB227ipx3T0f9Oflj09iWVT3C0saaAiCtpa50ggjImom1FAwNF0gLhPGbSgUzsHzAndwexXWD5StAfWuePaapbQ0IIAY9ahlTKCXGSV0oS/IrBDjOfIaXoyzzgT4/xTz6dwie2g255mGTDn6k0CYkWX19H8xzT2TQ7e4ikNrXVdcRRRy4rd22MA75546RVD2mm36C0DnaUsnBUwymuQ02z33iTm8U7CZXQWpiKjwgqCtvs9zrsRx1YECHCw5ehUDt2nMw4ino42jthxV9bgQDQg/On7frBUXeKkd7L0UVfC71DW9AQQTvdHA2POpPhtoi7BznOeFMoVXxBMgJSgwGTH3ErY0zbvMLJNNROXby4rABmb7XTl5bav5DYD2lWzhcseN6a+/PgREyzllQxJqWQVQvA00JFuaNFLI7JeyIULUgyYuS5n/jEvmKKnzhwuGlHnIKF5UPViaF3WRiFSTop6taZNptBFWGBsG7eT8rTxb/FKtylVw== cardno:20_514_162"
  ];

  system.stateVersion = "24.04";

  networking.enableIPv6 = true;
  security.acme = {
    # CHANGEME: email address you would like to use to get notifications about
    # SSL domain issues etc.
    defaults.email = "dpc@dpc.pw";
    acceptTerms = true;
  };

  networking = {
    firewall = {
      allowPing = true;

      allowedTCPPorts = [
        80
        443
      ];
    };
  };

  # General server stuff
  boot.tmp.cleanOnBoot = true;
  services.automatic-timezoned.enable = true;
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes repl-flake
    '';
    settings = {
      max-jobs = "auto";
      auto-optimise-store = true;
    };
    daemonIOSchedClass = "idle";
    daemonIOSchedPriority = 7;
    daemonCPUSchedPolicy = "idle";

    gc = {
      automatic = true;
      persistent = true;
      dates = "monthly";
      options = "--delete-older-than 30d";
    };

    settings = {
      keep-derivations = lib.mkForce false;
      keep-outputs = lib.mkForce false;
    };
  };
  services.journald.extraConfig = "SystemMaxUse=1G";

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  nix-bitcoin = {
    generateSecrets = true;
    operator = {
      enable = true;
      name = "operator";
    };
  };

  services.bitcoind = {
    enable = true;
    prune = 550;
    dbCache = 2200;
  };

  # give fedimintd user access to the bitcoind secret
  systemd.services.fedimintd-mainnet.serviceConfig = {
    SupplementaryGroups = "bitcoinrpc-public";
  };

  services.fedimintd."mainnet" = {
    enable = true;
    environment = {
      "RUST_LOG" = "info";
      "RUST_BACKTRACE" = "1";
      "FM_REL_NOTES_ACK" = "0_4_xyz";
    };
    api = {
      url = "wss://${fqdn}/ws/";
    };
    p2p = {
      url = "fedimint://${fqdn}:8173";
    };
    bitcoin = {
      network = "bitcoin";
      rpc = {
        url = "http://bitcoin@127.0.0.1:8332";
        secretFile = "/etc/nix-bitcoin-secrets/bitcoin-rpcpassword-public";
      };
    };
    nginx = {
      enable = true;
      inherit fqdn;
    };
  };

}
