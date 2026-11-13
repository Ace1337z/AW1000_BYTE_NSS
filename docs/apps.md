# BYTE 1.1.3 — page by page

Every menu entry that BYTE adds or changes, in the order you hit it. The stock
LuCI pages (firewall, DHCP, system, package manager) are untouched unless noted.

Open the WebUI at `http://192.168.1.1/`. Plain HTTP only: no 443 listener, no
redirect, no certificate warning, ever.

---

## Status

### Status → Overview

Vantage landing dashboard: uplink and downlink rate, CPU, memory, radio state,
SSID count, station list with signal, storage, and the network path from
`wwand0` to this access point.

The **System** panel is branded: hostname, model, kernel, local time, uptime and
`BYTE v1.1.3`. Architecture, target platform and load average were removed on
purpose. It is rewritten by a first-boot `uci-defaults` script, so a sysupgrade
never brings the stock panel back.

The **NET** widget understands vnStat 2.x JSON: the bucket and unit come from the
JSON itself, so a monthly figure is the month, not the all-time total, and it is
not scaled by 1024. vnStat 1.x still uses the KiB fallback.

### Status → Release RAM

`sync` + `drop_caches` on demand, for when the page cache has eaten the box after
a big download or a 9Router install.

### Status → Traffic Monitor

vnStat 2.13 graphs: summary, top talkers, 5-minute, hourly, daily, monthly,
yearly, per interface (`wwand0`, `br-lan`, radios). Clear-data button included.
The page is hidden behind a marker file by default; see [Hiding pages](#hiding-pages).

### Status → NSS Offload

Offload counters: ECM accelerated flows, NSS core load, per-core queue
statistics. This is how you confirm traffic is actually being forwarded by the
NSS and not by the CPU.

---

## Modem

### Modem → Modem info

LTE and 5G NSA signal side by side: RSRP, RSRQ, SINR, RSSI, CSQ/score. Carrier
aggregation table (PCC/SCC, band, bandwidth, frequency, PCI). Decoded cell
identity: MCC/MNC, cell id in hex and decimal, PCI, TAC, EARFCN, NR ARFCN. APN
and data session state below.

**Trend** sparklines for RSRP and SINR (LTE and 5G) render from
`/tmp/aw1000-status/history`. In 1.1.3 they are drawn with
`document.createElementNS`, so the shapes survive the SVG namespace — 1.1.2
showed a legend next to an empty plot.

### Modem → Messages

SMS inbox, read, send, delete. Backed by `sms-tool`.

### Modem → Bands

Per-band enable/disable for LTE and NR, network mode (automatic / LTE / 5G /
NSA / SA), and a live "in use now" line. Bands off steers the modem elsewhere;
it does not make a weak band stronger.

### Modem → Cell lock

Lock to a cell / PCI / ARFCN, and release the lock.

### Modem → AT commands

A raw AT console. QModem is pinned to `/dev/ttyUSB3`; `wwand` owns the data
path — do not point another daemon at the same port.

### Modem → TTL

QModem TTL and hop-limit rewrite for tethering policies. Moved to
`admin/modem/ttl` in 1.1.2, so it is back in the Modem menu instead of floating
under Services.

---

## Network

### Network → Interfaces

`wan` (the logical interface on `wwand0`, MTU **1420**), `lan` (`br-lan`,
`192.168.1.1/24`), `awg0` (AmneziaWG, present but down), and any additional
interfaces you add.

### Network → Wireless

`BYTE` on 2.4 GHz (ch 1) and 5 GHz (ch 149, 80 MHz), Wi-Fi 6, station list with
signal and rate. Country `US` by default — change it to your regulatory domain.

---

## Services

### Services → PassWall2

PassWall2 with Xray: nodes, subscriptions, routing rules, DNS mode, per-source
bypass. `dnsmasq-full` backs the resolver, and only DNS modes whose binary is
present are offered.

Proxied flows terminate in userspace, so they are not NSS-accelerated; direct
traffic still is. Per-source bypass rules give the NSS more to do.

### Services → Pass Wall

PassWall v1 **4.66-8**, vendored, Xray-only, **disabled by default**. It and
PassWall2 both install transparent-proxy rules and both want `:53`. Run one:
disable PassWall2 before enabling this.

### Services → Bandwidth Monitor

nlbwmon: per-host and per-protocol traffic accounting with graphs.

### Services → AWvoice (RJ11)

The RJ11 handset, driven by `awvoice-phoned` + `kmod-awvoice-fxs`:

- dial tone, ringing with caller ID, DTMF, hook flash, hold, call waiting,
  three-way conference
- contacts, quiet hours, call history, call recording, answering machine
- line state, SIP account, and a Linphone provisioning QR
- **Create a new password** rotates the LAN SIP password and shows it once

| SIP setting | Value |
| --- | --- |
| Server | `192.168.1.1` |
| Port | `5060` (UDP or TCP) |
| Username / auth | `awvoice` |
| Realm | `qmodem-voip` |
| RTP | UDP `40000–40031` |
| Codecs | PCMA / PCMU (G.711) |
| Interface | `lan` only |

The QR points at `http://192.168.1.1:8080/linphone.xml`, served by a separate
uhttpd instance whose document root is only `/www/awvoice-provision`. Never the
LuCI root, and plain HTTP, so no certificate warning.

> Default SIP password is shared and published. Anyone on the LAN who knows it
> can call through the SIM. Rotate it before using the router with people you do
> not trust, and never forward `5060` or `40000–40031` from the WAN.

### Services → AmneziaWG

Obfuscated WireGuard. Installed and pre-configured with one disabled client
interface and a placeholder peer: nothing starts at boot, no route is added, and
the module is not loaded until you enable it. Tunnel status, peer list and
obfuscation parameters live here.

---

## Tools

### Tools → BYTE

The control panel.

**AdGuard Home + PassWall2 setup** wires DNS for the whole LAN in one action:

```
LAN client :53 → AdGuard Home :53 → PassWall2 DNS 127.0.0.1:15353
dnsmasq moves to :54 for DHCP and .lan names
```

AdGuard Home is pulled from the firmware's own repository. The new config is
validated with `AdGuardHome --check-config` **before** it replaces the installed
one, so a bad write cannot take DNS down. Credentials land in
`/etc/agh-pw-backup/agh-admin.txt`.

In 1.1.3 this works: 1.1.2 wrote `192.168.1.1/24` (with prefix) into
`bind_hosts` and `http.address`, which take bare addresses, so validation failed
and the whole install rolled back. The first-run admin also failed with HTTP 400
because the install API bound the DNS address while dnsmasq still owned `:53`.

**Change password** sets a new AdGuard Home web admin password: new + repeat,
minimum 8 characters. It stops AdGuard Home, rewrites the bcrypt hash in
`users:`, validates with `--check-config`, starts it again and updates the
plaintext backup. The hash comes from the static `agh-passwd` helper, so no
Python, Perl or `htpasswd` is needed. No old password required.

The panel also shows PassWall2 state and node count, and the live DNS chain with
each hop's real state.

### Tools → IPv6

One switch for the whole IPv6 path: modem PDP type, LAN router advertisements
and DHCPv6, and dnsmasq AAAA filtering. It redials the modem, so expect IPv4 to
drop for 10–30 s. Backed by the same `byte` rpcd object as the panel:

```sh
ubus call byte ipv6_mode '{"action":"status"}'
```

Default is IPv4-only because this carrier hands out a prefix it does not route:
`ip -6 route get 2606:4700:4700::1111` answers *Network unreachable* and every v6
flow dies in ~2 ms. With RA advertising that prefix, browsers tried AAAA first,
failed, then retried over IPv4 — pages loaded, not instantly. When your carrier
routes the prefix, flip this switch.

### Tools → 9Router

Local LLM gateway: install from the page, service state, node list and request
graphs. Not part of the base image — reinstall after an upgrade; data in
`/srv/9router` is kept.

---

## System

### System → File Manager

Browse, upload, download, edit and delete files on the overlay and on USB
storage. Backed by `rpcd-mod-file` plus the exfat/ext4/ntfs3/vfat modules.

### System → Scheduled Tasks

Cron, visible by default. Useful for restarts and for the phone daemon's quiet
hours.

### System → Administration

Root password, SSH access, hostname, timezone. Timezone defaults to
`Asia/Kuala_Lumpur` (`<+08>-8`, `zonename=Asia/Kuala_Lumpur`).

---

## Hidden pages

`Status → Traffic Monitor` is hidden unless the marker file exists:

```sh
touch /etc/aw1000/show-vnstat2
rm -f /tmp/luci-indexcache*      # LuCI caches the menu
```

Remove the file to hide it again. The marker is checked by
`/usr/share/luci/menu.d/zz-aw1000-hide-vnstat2.json`.

## After an upgrade

- Hard-refresh with **Ctrl+Shift+R** if a panel looks like the old layout —
  LuCI caches panel JS hard.
- 9Router must be reinstalled from its page; its data survives.
- AdGuard Home, if installed, survives in `/etc/adguardhome` and
  `/etc/agh-pw-backup`.
- Config is kept by `sysupgrade` unless you passed `--wipe`.
