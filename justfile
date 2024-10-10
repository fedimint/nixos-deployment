# CHANGEME
FQDN := "myfedimint.net"
SSH_HOST := "root@{{FQDN}}"
FLAKE_CONF := "myfedimint"

[private]
default:
  @just --list

# Apply (deply) configuration to a host
apply conf=FLAKE_CONF ssh_host=SSH_HOST:
  nixos-rebuild switch -L --flake .#{{conf}} --target-host "{{ssh_host}}"

# Bootstrap host using nixos-anywhere
bootstrap conf=FLAKE_CONF ssh_host=SSH_HOST:
  nix run github:nix-community/nixos-anywhere -- --flake .#{{conf}} {{ssh_host}}

# Check for problems
check:
  nix flake check
  just --evaluate
