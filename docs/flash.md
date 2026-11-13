# Flashing BYTE

BYTE ships one artifact: a squashfs **sysupgrade** image. There is no factory
image, no web-UI installer and no initramfs in the release. The installer is a
small shell script that checks a per-device licence, downloads the image over
HTTPS, verifies the sha256 and calls `sysupgrade -v`.

Read [Recovery](#recovery) before you run it. A flash you cannot undo is a brick.

---

## 1. Get the device id

```sh
sh -c "$(curl -fsSL https://byte-gate.pages.dev/i.sh)" --id
```

or, with the script already on the box:

```sh
curl -fsSL https://byte-gate.pages.dev/i.sh -o /tmp/install.sh
sh /tmp/install.sh --id
```

It prints 24 hex characters and nothing else on stdout. That id is
`sha256(eth0 + br-lan + phy0-ap0 + phy1-ap0 MAC)`, truncated. It contains no
IMEI, ICCID, subscriber or traffic data.

Send it to **[@bytewrt](https://t.me/bytewrt)** on Telegram. Getting the id is
also what records the install request, so you do not have to explain anything
else. Approval is manual.

## 2. Install

```sh
sh -c "$(curl -fsSL https://byte-gate.pages.dev/i.sh)"
```

Nothing is written to disk and your terminal keeps stdin, so the confirmation
prompt works. The same thing step by step:

```sh
curl -fsSL https://byte-gate.pages.dev/i.sh -o /tmp/install.sh
sh /tmp/install.sh
```

Do **not** pipe it into `sh`:

```sh
curl -fsSL https://byte-gate.pages.dev/i.sh | sh     # refused
```

The prompt would read the script from its own body. The installer detects a
non-terminal stdin and refuses instead of flashing. `-y` is for genuinely
unattended runs; the sha256 still has to match.

A passing gate tells you so:

```
== device id: 33736085cce498b4eca13fb0
== licence ok (permanent): this device may install BYTE-1.1.3
== downloading BYTE-1.1.3
```

Temporary licences print the remaining window instead:

```
== licence ok (7d left until 2026-11-20)
```

If the operator left a message it is printed before anything downloads:

```
---- message from the vendor ----
maintenance window: Sunday 02:00-03:00 MYT
---------------------------------
```

### Order of operations

1. licence check — a denial happens here, before any byte is downloaded
2. signed download, resumable
3. sha256 verification against the server value
4. confirmation prompt (skipped by `-y`)
5. `sysupgrade -v` — config kept

### Flags

```sh
sh install.sh BYTE-1.1.3     # pin a tag
sh install.sh --wipe         # erase config (-n) — explicit only
sh install.sh -y             # no prompt
BYTE_YES=1 sh install.sh     # same, via env
BYTE_API=https://host sh install.sh   # override the licence endpoint
```

Arguments work in both the one-liner and the two-step form.

### What it will never do

- Pass `-F`. That skips board and metadata validation and is a brick vector.
- Wipe config unless `--wipe` is passed.
- Flash an image whose sha256 differs from the server value.
- Gate halfway: a denial never leaves a partial image behind.

### Resumed transfers

The installer uses `curl -C -` with `--retry 5 --retry-delay 2
--retry-all-errors`, and the server answers `Range` requests with `206`. If the
mobile uplink stalls or the modem redials mid-download, the next attempt
continues from the byte it reached. The sha256 check is still the authority.

## 3. Requirements on the device

- OpenWrt with `curl`, `jsonfilter`, `sha256sum` and `sysupgrade` — all present
  in 1.1.x.
- About 45 MB free in `/tmp` (image is 37,171,460 bytes; `/tmp` is tmpfs).
- Working WAN. Both the check and the download need it, so run this while the
  current firmware still has connectivity.

## 4. Downtime

`sysupgrade` reboots the box and redials the modem. Expect 2–4 minutes without
internet for every LAN and Wi-Fi client. Proxied clients reconnect after the
dial.

## 5. Verify after boot

```sh
cat /tmp/sysinfo/board_name                  # arcadyan,aw1000
cat /etc/openwrt_release | grep -i byte      # BYTE 1.1.3
uci -q get network.wwan.mtu                  # 1420
ip link show wwand0 | grep -o 'mtu [0-9]*'   # mtu 1420
cat /sys/class/net/wwand0/type               # 519 (raw-IP, NSS-bound)
dmesg | grep 'raw-IP interface bound to rmnet_rx node'
cat /sys/kernel/debug/ecm/ecm_nss_ipv4/accelerated_count   # > 0 under load
```

`type` reading `1` means the modem netdev stayed `ARPHRD_ETHER` and NSS never
bound it. Re-check the image tag and report it.

## Recovery

Flashing a sysupgrade image is reversible only if you can reach the bootloader.

**Before flashing:**

1. Save the config and copy it off the box:
   `sysupgrade -b /tmp/backup.tar.gz` then `scp root@192.168.1.1:/tmp/backup.tar.gz .`
2. Keep the previous release image and its sha256 on your computer.
3. Know the serial pinout and the U-Boot TFTP procedure for **your** board
   revision. Do not guess pin locations or memory addresses — take them from the
   vendor documentation or from a teardown of the exact board.

**If it does not come back after ~5 minutes:**

1. Open the case and attach serial at **115200 8N1**, 3.3 V levels. Do not feed
   5 V into the UART.
2. Power on and interrupt U-Boot during the countdown.
3. Set the board's IP and the TFTP server address, then load and write the
   known-good image using the addresses printed by the vendor recovery
   procedure. Do not invent offsets.
4. Boot, restore the config backup if needed.

Without serial access recovery means opening the case, so do not flash a device
you cannot physically reach. If you have never done this on an AW1000, practise
the serial + TFTP recovery on the running firmware first.

## Troubleshooting

| Symptom | Meaning |
| --- | --- |
| `not licensed (http 403)` | request recorded, not approved yet. Re-run after approval. |
| `not licensed` after a temporary window | licence expired. Ask for another window. |
| Gate passes, download stalls | client uplink or carrier. Re-run: it resumes. |
| sha256 mismatch | image never flashed. Re-run; if it repeats, report the tag. |
| LuCI answers but pages look old | hard-refresh with **Ctrl+Shift+R** (LuCI caches panel JS). |
| No internet after boot | `ifstatus wan`, `ubus call network.interface.wan status`; interface is `wwand0`. |

Never use `-F`, and never write a raw image over a running system to "fix" a bad
flash. Serial console is the recovery path.

## Privacy

The gate sees: the device id, the tag requested, your country, timestamps, and
download/activation counters keyed by that id. It never sees traffic, IMEI,
ICCID, MSISDN or the SIM's identity. Licences are per device id, not per person.
Deleting a licence at the operator end removes the id, request and counters.
