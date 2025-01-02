{
  modulesPath,
  lib,
  pkgs,
  ...
}:

let
  # CHANGEME: register a DNS domain, and make it point at IP of your fedimint server
  # Typically you can use `ip ad ls | grep global` command on the server to find this value.
  fqdn = "myfedimint.net";
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
    "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAklOUpkDHrfHY17SbrmTIpNLTGK9Tjom/BWDSUGPl+nafzlHDTYW7hdI4yZ5ew18JH4JW9jbhUFrviQzM7xlELEVf4h9lFX5QVkbPppSwg0cda3Pbv7kOdJ/MTyBlWXFCR+HAo3FXRitBqxiX1nKhXpHAZsMciLq8V6RjsNAQwdsdMFvSlVK/7XAt3FaoJoAsncM1Q9x5+3V0Ww68/eIFmb1zuUFljQJKprrX88XypNDvjYNby6vw/Pb0rwert/EnmZ+AW4OZPnTPI89ZPmVMLuayrD2cE86Z/il8b+gw3r3+1nKatmIkjn2so1d01QraTlMqVSsbxNrRFi9wrf+M7Q== schacon@mylaptop.local"
  ];

  system.stateVersion = "24.04";

  networking.enableIPv6 = true;
  security.acme = {
    # CHANGEME: email address you would like to use to get notifications about
    # SSL domain issues etc.
    defaults.email = "youremail@proton.me";
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
    
    extraConfig = ''
      # minimum memory usage settings, even on mainnet it will be slow but will work just fine
      maxmempool=5
      par=2
      rpcthreads=4
      maxconnections=32
    '';
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
