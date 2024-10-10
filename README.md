# Fedimint NixOS deployment template

Using this template you can easily setup up a Fedimint instance on a new NixOS Linux server.


### Be aware of limitations and constrains

Note that Fedimint is still immature, so hitting bugs or issues is not only possible, but somewhat likely.
Proceed with caution. Consider joining Fedimint's Discord channel and asking for help in the `#mint-ops` channel.


## Get a group of people

The security and robustness of Fedimint is based on its Federated model.

The minimal recommended setup requires 4 independent actors, each running own Fedimint instance.

For maximum security each should use a different DNS and hosting provider/solution.

Each will have to follow this or similar instructions independently.


## Get a server

A small Fedimint instance should be OK with 4GB of memory and 2 vCPUS. 60GB or more of
SSD storage is recommended to store both the pruned `bitcoind` state and `fedimintd` data.


## Setup DNS domain

A Fedimint instance requires a valid DNS domain that will point to `fedimintd` server. Register it if you
don't have one yet. We'll call it `DOMAIN` from now on in the examples.

Configure the `DOMAIN` to point at the server's IP address value. Verify that `ping -n <full-domain-name>` resolves to the correct address.


## Setup ssh access to your server

Log into your server with `ssh@DOMAIN`. Ensure that you are using ssh key to access it. This is required later.
Use `ssh-copy-id root@DOMAIN` to install your public key on the machine.

Use `df /` to record the root disk filesystem path.


## Fork, clone and customize this template

You should do it once and use your local copy to set up and customize your host over time.

This template contains a couple of `CHANGEME` comments. Find all of them and change to values from your server/domain.


### Install Nix

You will need Nix installed on your system to compile and run Nix-related software.

We recommend using https://github.com/DeterminateSystems/nix-installer if you don't
have Nix setup yet: Run `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`.

Enter the development shell with `nix develop`. This should give you access to all the useful tools for steps
below.

## Deploy NixOS server

We'll use `nixos-anywhere` project to turn the initial existing Linux system on the server into a NixOS setup:

You should be able to retry it until you figure out all the details and it works.

Run:

```
just bootstrap
```

If it succeeds, you have a fully configured NixOS system, with fedimintd configured,
that you can `ssh` into just as before.


#### Optional: building on remote machine

If you can't build x86_64-linux packages on your local OS (e.g. you're a MacOS users)
you might use the target system (server) as a build machine itself. This might require more
disk space and take longer, as the server is probably slower than your local machine.

Use:

```
just bootstrap-build-on-remote
```

instead of plain `just boostrap` to use this method.


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

TODO: A `just` command that automatically populates the bitcoind data dir with
prunednode.today download.

## Deploying changes

After the initial `nixos-anywhere` installation, you can always use:

```
just apply
```

to deploy to server any changes you made in the configuration.

If you can't build for `linux-x86_64` locally use

```
just apply-build-on-remote
```

instead.


## Complete DKG

At the time of setting up the federation (aka. DKG), Fedimint requires the same versions of the
`fedimintd` on all peers. You can verify it by running `fedimint --version` before attempting
the DKG. In some near future version this limitation will be relaxed and verification itself automatic.

After all guardians of your Federation are ready, use `fedimint-ui` interface to connect to
your Fedimint instance and complete DKG. (To be described in more details in the future).
