# opnsense-igmpv3proxy

OPNsense plugin package for managing igmpv3proxy.

## Features

- Configuration generation for `igmpv3proxy`
- Multiple downstream interfaces
- Optional source filtering for IGMPv3/SSM
- Manual network entries or firewall alias based configuration
- Diagnostics view for generated configuration and runtime output

## Limitations

- Experimental third-party package, not an official OPNsense plugin.
- Built and tested on OPNsense 26.1 / FreeBSD 14.3 amd64.
- Does not manage firewall rules.
- Includes a prebuilt `igmpv3proxy` binary for FreeBSD 14.3 amd64.
- Source filters are generated as `up allow`; direction and action are not configurable.
- Firewall aliases are resolved only from static IPv4 network aliases.
- Multicast whitelist aliases must contain multicast IPv4 networks.
- Source aliases must contain non-multicast IPv4 networks.

## Package

The release package includes the `igmpv3proxy` binary and does not require local compilation.

## Install

Download and install the package from GitHub Releases:

```sh
pkg add -f https://github.com/grisey/opnsense-igmpv3proxy/releases/download/v0.1/os-igmpv3proxy-0.1.pkg
service configd restart
configctl webgui restart
```
