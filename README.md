# opnsense-igmpv3proxy

OPNsense plugin package for managing igmpv3proxy with an MVC GUI.

## Features

- IGMPv3 proxy service integration for OPNsense
- MVC settings page
- diagnostics page
- config generation from `/conf/config.xml`
- multiple downstream interfaces
- manual or firewall-alias based multicast whitelists
- optional source filtering
- service controls via OPNsense configd
- boot autostart via OPNsense syshook when enabled

## Package

The release package includes the igmpv3proxy binary and does not require local compilation.

## Install

See `INSTALL.md`.
