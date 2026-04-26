#!/usr/local/bin/python3

import ipaddress
import os
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

CONFIG = Path("/conf/config.xml")
OUTPUT = Path("/usr/local/etc/igmpv3proxy.conf")

def text(node, name, default=""):
    child = node.find(name)
    if child is None or child.text is None:
        return default
    return child.text.strip()

def enabled(value):
    return str(value).strip().lower() in ("1", "yes", "true", "on")

def split_list(value):
    result = []
    for item in str(value).replace("\n", ",").split(","):
        item = item.strip()
        if item:
            result.append(item)
    return result

def parse_network(value, name):
    try:
        return ipaddress.ip_network(value, strict=False)
    except Exception as exc:
        raise SystemExit(f"{name}: invalid network {value!r}: {exc}")

def require_multicast_network(value, name):
    net = parse_network(value, name)
    if net.version != 4:
        raise SystemExit(f"{name}: only IPv4 networks are supported")
    if not net.is_multicast:
        raise SystemExit(f"{name}: {value!r} is not an IPv4 multicast network")
    return str(net)

def require_source_network(value, name):
    net = parse_network(value, name)
    if net.version != 4:
        raise SystemExit(f"{name}: only IPv4 networks are supported")
    if net.is_multicast:
        raise SystemExit(f"{name}: {value!r} must not be multicast")
    return str(net)

def config_root():
    return ET.parse(CONFIG).getroot()

def physical_interface(root, logical_name):
    interfaces = root.find("interfaces")
    if interfaces is None:
        raise SystemExit("interfaces section missing in config.xml")

    iface = interfaces.find(logical_name)
    if iface is None:
        raise SystemExit(f"interface {logical_name!r} not found in config.xml")

    real_if = text(iface, "if")
    if not real_if:
        raise SystemExit(f"interface {logical_name!r} has no <if> mapping")

    return real_if

def get_model_root(root):
    opnsense = root.find("OPNsense")
    if opnsense is None:
        raise SystemExit("OPNsense section missing in config.xml")

    model = opnsense.find("Igmpv3proxy")
    if model is None:
        raise SystemExit("Igmpv3proxy section missing in config.xml")

    return model

def find_firewall_alias(root, alias_name):
    matches = []

    for alias in root.findall(".//aliases/alias"):
        if text(alias, "name") == alias_name:
            matches.append(alias)

    if not matches:
        raise SystemExit(f"alias {alias_name!r} not found")

    if len(matches) > 1:
        raise SystemExit(f"alias {alias_name!r} found multiple times")

    alias = matches[0]
    alias_type = text(alias, "type")
    alias_enabled = text(alias, "enabled", "1")
    alias_content = text(alias, "content")

    if alias_enabled not in ("", "1"):
        raise SystemExit(f"alias {alias_name!r} is disabled")

    if alias_type != "network":
        raise SystemExit(f"alias {alias_name!r}: unsupported alias type {alias_type!r}")

    if not alias_content:
        raise SystemExit(f"alias {alias_name!r}: empty content")

    return split_list(alias_content)

def resolve_source_networks(root, model):
    if enabled(text(model, "source_filter_alias_enabled", "0")):
        alias_name = text(model, "source_filter_source_alias")
        if not alias_name:
            raise SystemExit("source_filter_source_alias missing")
        raw_items = find_firewall_alias(root, alias_name)
        return [require_source_network(item, f"alias {alias_name}") for item in raw_items]

    raw = text(model, "source_filter_sources", "87.141.0.0/16")
    items = split_list(raw)
    if not items:
        raise SystemExit("source_filter_sources missing")
    return [require_source_network(item, "source_filter_sources") for item in items]

def resolve_multicast_networks(root, model, enabled_field, alias_field, manual_field, fallback, label):
    if enabled(text(model, enabled_field, "0")):
        alias_name = text(model, alias_field)
        if not alias_name:
            raise SystemExit(f"{alias_field} missing")
        raw_items = find_firewall_alias(root, alias_name)
        return [require_multicast_network(item, f"alias {alias_name}") for item in raw_items]

    raw = text(model, manual_field, "")
    if not raw:
        raw = text(model, "whitelist", fallback)

    items = split_list(raw)
    if not items:
        raise SystemExit(f"{manual_field} missing")

    return [require_multicast_network(item, label) for item in items]

def render(root, model):
    if not enabled(text(model, "enabled", "0")):
        raise SystemExit("igmpv3proxy is disabled")

    quickleave = enabled(text(model, "quickleave", "1"))

    upstream = text(model, "upstream")
    if not upstream:
        raise SystemExit("upstream missing")

    downstreams_raw = text(model, "downstreams", "")
    if not downstreams_raw:
        downstreams_raw = text(model, "downstream", "")

    downstreams = split_list(downstreams_raw)
    if not downstreams:
        raise SystemExit("downstreams missing")

    upstream_whitelist = resolve_multicast_networks(
        root,
        model,
        "upstream_whitelist_alias_enabled",
        "upstream_whitelist_alias",
        "upstream_whitelist",
        "232.0.0.0/8",
        "upstream_whitelist"
    )

    downstream_whitelist = resolve_multicast_networks(
        root,
        model,
        "downstream_whitelist_alias_enabled",
        "downstream_whitelist_alias",
        "downstream_whitelist",
        "232.0.0.0/8",
        "downstream_whitelist"
    )

    upstream_if = physical_interface(root, upstream)

    downstream_ifs = []
    for downstream in downstreams:
        downstream_if = physical_interface(root, downstream)
        if downstream_if == upstream_if:
            raise SystemExit(f"downstream {downstream!r} resolves to upstream interface {upstream_if!r}")
        if downstream_if not in downstream_ifs:
            downstream_ifs.append(downstream_if)

    source_filters = []
    if enabled(text(model, "source_filter_enabled", "0")):
        source_nets = resolve_source_networks(root, model)
        for src in source_nets:
            for dst in upstream_whitelist:
                source_filters.append((src, dst))

    lines = []

    if quickleave:
        lines.append("quickleave")
        lines.append("")

    lines.append(f"phyint {upstream_if} upstream ratelimit 0 threshold 1")
    if source_filters:
        for src, dst in source_filters:
            lines.append(f"        filter {src} {dst} up allow")
    else:
        for net in upstream_whitelist:
            lines.append(f"        whitelist {net}")

    for downstream_if in downstream_ifs:
        lines.append("")
        lines.append(f"phyint {downstream_if} downstream ratelimit 0 threshold 1")
        for net in downstream_whitelist:
            lines.append(f"        whitelist {net}")

    return "\n".join(lines).rstrip() + "\n"

def main():
    root = config_root()
    model = get_model_root(root)
    content = render(root, model)

    fd, tmpname = tempfile.mkstemp(prefix=OUTPUT.name + ".", dir=str(OUTPUT.parent))
    try:
        with os.fdopen(fd, "w") as f:
            f.write(content)
        os.chmod(tmpname, 0o644)
        os.replace(tmpname, OUTPUT)
    finally:
        if os.path.exists(tmpname):
            os.unlink(tmpname)

    print(f"generated {OUTPUT}")

if __name__ == "__main__":
    main()
