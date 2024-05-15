# Fedimint NixOS deployment template

Using this template you can easily setup up a Fedimint instance.


### Be aware of limitations and constrains

Note that Fedimint is still immature, so hitting bugs or issues is not only possible, but somewhat likely.
Proceed with caution. Consider joining Fedimint's Discord channel and asking for help in the `#mint-ops` channel.

At the time of setting up the federation (aka. DKG), Fedimint requires git-hash identical version of the
`fedimintd`. You can verify it by running `fedimint version-hash` before starting the final process. In some near future
version this limitation will be relaxed and verification itself automatic.


## Get a group of people

The security and robustness of Fedimint is based on its Federated model.

The minimal recommended setup requires 4 independent actors, each running own Fedimint instance.

For maximum security each should use a different DNS and hosting provider/solution.

Each will have to follow this or similar instructions independently.


## Clone and customize this template

You should do it once and use your local copy to set up and customize your host over time.

This template contains a couple of `CHANGEME` comments. Look for them and make adjustments. You might need information
from the next steps to complete it.


## Get a server

A small Fedimint instance should be OK with 4GB of memory and 2 vCPUS. 60GB or more of
SSD storage is recommended to store both the pruned `bitcoind` state and `fedimintd` data.

Note the IP address and disk drive path of the server, as it will be important later.


## Get DNS domain

A Fedimint instance requires a valid DNS domain that will point to `fedimintd` server. Register it if you
don't have one yet. We'll call it `DOMAIN` from now on in the examples.

Configure the:

* `api`
* `p2p`
* `admin`

`A` records with the server's IP address value.


## Set up NixOS server

Not a lot of hosting providers make NixOS available but `nixos-anywhere` project allows turning
any existing Linux system into a NixOS setup:

https://github.com/nix-community/nixos-anywhere

This is probably the most difficult step here, but you should be able to retry it until you figure
it out.

If you have a choice, we recommend running `nixos-anywhere` against CentOS Linux already installed
on the server.

If you correctly customized the template (primarily added your ssh key and set the disk device path to correct value)
it should come down to:

```
nix run github:nix-community/nixos-anywhere -- --flake .#myfedimint root@DOMAIN
```

If it succeeds, you should get a fully configured NixOS system.

#### Install Nix

You will need Nix installed on your system to compile and run Nix-related software.

We recommend using https://github.com/DeterminateSystems/nix-installer if you don't
have Nix setup yet.

#### Optional: build on remote machine

If you can't build x86_64-linux packages on your local OS (e.g. MacOS users) you might use the target system
(server) as a build machine using `--build-on-remote` argument, but it needs Nix installed (just Nix, not NixOS)
beforehand. Use https://github.com/DeterminateSystems/nix-installer - run the installation shell command **on the
server**.

Then use:

```
nix run github:nix-community/nixos-anywhere -- --build-on-remote --flake .#myfedimint root@DOMAIN
```

from your local machine.


#### Deploy changes

After the initial `nixos-anywhere` installation, you can always use:

```
nixos-rebuild switch --flake .#myfedimint --target-host root@DOMAIN
```

to deploy any changes you made to the configuration.

If you can't build for `linux-x86_64` locally use

```
nixos-rebuild switch --flake .#myfedimint --build-host root@DOMAIN --target-host root@DOMAIN
```

instead.


## Wait for `bitcoind` to sync

The server will be running `bitcoind` started with an empty state. It would take a very
long time to have it complete IBD from scratch.

You can check the logs with:

```
journalctl -u bitcoind.service -f
```

You can stop it and download the state from https://prunednode.today/ or upload your own
data directory to speed up the process.

In the default configuration the pruned note will take around 12GB of storage.


## Verify DNS and admin interface

The `A` records you set before should work, in particular `https://admin.DOMAIN` should greet you with a Fedimint Admin
UI web interface.


## Complete DKG

After all guardians of your Federation are ready, point your browser at `https://admin.DOMAIN`
which should greet you and allow setting up and managing your Federation.
