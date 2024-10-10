This is meant to supplement the main `README.md`, with extra details
specific to Hetzner's Cloud instances.

Follow the instruction in README.md, and refer to corresponding sections below.

### Get a server

Register new Hetzner Cloud VM

* Pick location: any will do
* Pick Image: Fedora 40 was tested, any should do
* Pick Type: Shared vCPU is OK, minimal CX22 is OK and tested, CPX21 recommended due to larger storage
* Netoworking: IPv4+IPv6 recommended, IPv6-only would work, but not very practical
* SSH keys: Add your public ssh key
* Leave rest as is
* Create and buy


### Setup DNS domain

* Record server's IP address
* Go to your preferred DNS registrar, create A record pointing at the IP
* Verify that `ping -n DOMAIN` resolves to the correct address


### Setup ssh access to your server

Notably Hetzner's VPSes use `/dev/sda` 
