{ modulesPath, lib, pkgs, ... }:

let
  # CHANGEME: register a DNS domain, and make
  # api.<domain>
  # p2p.<domain>
  # admin.<domain>
  # a `A` record with the IP of your fedimint server
  # Typically you can use `ip ad ls | grep global` command on the server to find this value.
  fmFqdn = "myfedimint.net";
  fmApiFqdn = "api.${fmFqdn}";
  fmP2pFqdn = "p2p.${fmFqdn}";
  fmAdminFqdn = "admin.${fmFqdn}";
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

  system.stateVersion = "23.11";

  networking.enableIPv6 = true;

  # CHANGEME: email address you would like to use to get notifications about
  # SSL domain issues etc.
  security.acme.defaults.email = "youremail@proton.me";
  security.acme.acceptTerms = true;

  networking = {
    firewall = {
      allowPing = true;

      allowedTCPPorts = [ 80 443 ];
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

  users.extraUsers.fedimintd-mainnet.extraGroups = [ "bitcoinrpc-public" ];

  services.fedimintd."mainnet" = {
    enable = true;
    package = pkgs.fedimintd;
    extraEnvironment = {
      "RUST_LOG" = "info";
      "RUST_BACKTRACE" = "1";
    };
    api = {
      address = "wss://${fmApiFqdn}/ws/";
      bind = "127.0.0.1";
    };
    p2p = {
      address = "fedimint://${fmP2pFqdn}:8173";
      openFirewall = true;
      bind = "0.0.0.0";
    };
    bitcoin = {
      network = "bitcoin";
      rpc = {
        address = "http://public@127.0.0.1:8332";
        secretFile = "/etc/nix-bitcoin-secrets/bitcoin-rpcpassword-public";
      };
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."${fmApiFqdn}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8045/";
        extraConfig = "proxy_pass_header Authorization;";
      };
      locations."/ws/" = {
        proxyPass = "http://127.0.0.1:8174/";
        proxyWebsockets = true;
        extraConfig = "proxy_pass_header Authorization;";
      };
      locations."= /meta.json" = {
        alias = "/var/www/meta.json";
        extraConfig = ''
          add_header Access-Control-Allow-Origin '*';
        '';
      };
      locations."/federation_assets/" = {
        alias = "/var/www/static/";
        extraConfig = ''
          add_header Access-Control-Allow-Origin '*';
        '';
      };
    };


    virtualHosts."${fmAdminFqdn}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        root = pkgs.fedimint-ui;
      };
      locations."=/config.json" = {
        alias = pkgs.writeText "config.json"
          ''
            {
                "fm_config_api": "wss://${fmApiFqdn}/ws/",
                # CHANGEME: ToS that will be displayed to the Admin
                "tos": "ToS "
            }
          '';
      };
    };
  };
}
