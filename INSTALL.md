# Install

Download and install the package from GitHub Releases:

pkg add -f https://github.com/grisey/opnsense-igmpv3proxy/releases/download/v0.1/os-igmpv3proxy-0.1.pkg
service configd restart
configctl webgui restart

After installation, open:

Services -> IGMPv3 Proxy
