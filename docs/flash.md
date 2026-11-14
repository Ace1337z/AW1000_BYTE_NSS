# Flashing BYTE

BYTE ships one artifact: a squashfs **sysupgrade** image. There is no factory
image, no web-UI installer and no initramfs in the release. The installer is a
small shell script that checks a per-device licence, downloads the image over
HTTPS, verifies the sha256, runs the firmware's own image check, and only then
calls `sysupgrade`.

It runs on **BYTE and on any other OpenWrt build for this board**. That matters:
most owners arrive from stock OpenWrt, which has no `curl`. The installer needs
`sysupgrade`, a sha256 tool and one of `curl`/`uclient-fetch`/`wget`; nothing
else has to be installed.

Read [Recovery](#recovery) before you run it. A flash you cannot undo is a brick.

---

## 1. Get the device id

```sh
# wget exists on every OpenWrt; the "&&" makes a failed download print an error
wget -qO /tmp/byte-i.sh https://byte-gate.pages.dev/i.sh && sh /tmp/byte-i.sh --id
```

or, with the script already on the box:

```sh
curl -fsSL https://byte-gate.pages.dev/i.sh -o /tmp/byte-i.sh
sh /tmp/byte-i.sh --id
```

It prints 24 hex characters and nothing else on stdout. That id is
`sha256(eth0 + br-lan + phy0-ap0 + phy1-ap0 MAC)`, truncated. It contains no
IMEI, ICCID, subscriber or traffic data.

Send it to **[@bytewrt](https://t.me/bytewrt)** on Telegram. Requesting the id is
also what records the install request, so you do not have to explain anything
else. Approval is manual.

## 2. Install

```sh
wget -qO /tmp/byte-i.sh https://byte-gate.pages.dev/i.sh && sh /tmp/byte-i.sh
```

That is the form to use. It needs no `curl`, it survives a failed fetch, and your
terminal keeps stdin so the confirmation prompt works. The same thing with curl:

```sh
curl -fsSL https://byte-gate.pages.dev/i.sh -o /tmp/byte-i.sh && sh /tmp/byte-i.sh
```

Do **not** pipe it into `sh`:

```sh
curl -fsSL https://byte-gate.pages.dev/i.sh | sh     # refused
```

The prompt would read the script from its own body, so the installer detects a
non-terminal stdin and refuses instead of flashing. `-y` is for genuinely
unattended runs; the sha256 still has to match.

You do not need an empty root password. The installer runs in the session you
already opened over SSH or the serial console, so whatever root password the
router has is the one it uses. It never reads, sets or resets credentials.

A passing run looks like this:

```
== BYTE installer v5
== device id: 33736085cce498b4eca13fb0
== this box: Arcadyan AW1000 [arcadyan,aw1000] running OpenWrt 24.10.4
== licence ok (permanent): this device may install BYTE-1.1.4
== WARNING: config will be ERASED (-n)
   about to flash BYTE-1.1.4 and ERASE the config. type yes to continue: yes
== downloading BYTE-1.1.4 (~37 MB, the router stays online until the flash)
== downloaded 37171460 bytes, verifying sha256
   sha256 OK
   signature OK (ed25519 dcdb9655603fd9a0)
== image check with this firmware's own verifier (no write)
   image check passed
== flashing BYTE-1.1.4
== done, the router is rebooting into BYTE-1.1.4
```

### The script and the image are signed

One ed25519 key signs both. The private half stays on the release machine — it
is not a Cloudflare secret — so a compromised gate can withhold a release but
cannot forge a different one.

```
fingerprint  dcdb9655603fd9a0
public key   https://raw.githubusercontent.com/Ace1337z/AW1000_BYTE_NSS/main/pubkey/byte-signing.pub
```

Verify the installer before running it as root:

```sh
wget -qO /tmp/byte-i.sh.sig https://byte-gate.pages.dev/i.sh.sig
wget -qO /tmp/byte-signing.pub \
  https://raw.githubusercontent.com/Ace1337z/AW1000_BYTE_NSS/main/pubkey/byte-signing.pub
usign -F -p /tmp/byte-signing.pub        # must print dcdb9655603fd9a0
usign -V -q -p /tmp/byte-signing.pub -m /tmp/byte-i.sh -x /tmp/byte-i.sh.sig
```

Every BYTE image ships `/usr/bin/usign`, so the installer repeats that check
against `/sig/<tag>` before it flashes. A signature that is present but wrong
is always fatal; a tag with no signature, or a box without `usign`, warns and
falls back to sha256. Set `BYTE_REQUIRE_SIG=1` on the command line to make both
of those refusals instead:

```sh
BYTE_REQUIRE_SIG=1 sh /tmp/byte-i.sh
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
2. board check — refuses a box that does not identify as an AW1000
3. confirmation prompt — **before** the transfer, so a wrong answer costs nothing
4. download, resumable
5. sha256 verification against the server value
6. ed25519 signature check — `/sig/<tag>` verified with the embedded release key
7. `sysupgrade -T` — the running firmware's own image check (metadata, board
   match, config compat, signature policy) with **no write**
8. read-only pre-flight — walks the same chain `nand_do_upgrade` will walk
   (UBI device, the mtd name `find_mtd_index` resolves, the `kernel` / `rootfs`
   / `rootfs_data` volumes, `ubi-utils`, reusable eraseblocks, the `kernel` and
   `root` members inside the image) so a write that cannot work stops here
   instead of ending in a silent reboot
9. `sysupgrade -v -n` — **config erased**

Step 7 is why a refusal is reported before anything is written: the check that
`sysupgrade` would run itself is run first, on the same image, by the same code.

### Flags

```sh
sh /tmp/byte-i.sh BYTE-1.1.4   # pin a tag, config still erased
sh /tmp/byte-i.sh              # the only mode: erase config (-n)
sh /tmp/byte-i.sh --check      # dry run: board, licence, space, sha256
sh /tmp/byte-i.sh --debug      # set -x trace for support
sh /tmp/byte-i.sh -y           # no prompt
BYTE_YES=1 sh /tmp/byte-i.sh   # same, via env
BYTE_API=https://host sh /tmp/byte-i.sh   # override the licence endpoint
BYTE_REQUIRE_SIG=1 sh /tmp/byte-i.sh      # refuse a tag with no signature
```

### What it will never do

- Pass `-F`. That skips board and metadata validation and is a brick vector.
- Keep a config. There is one flash mode, a clean install (`sysupgrade -n`) —
  the same result as LuCI's **System → Backup / Flash Firmware** with
  **Keep settings** unticked. `--keep` exits with an explanation rather than
  silently wiping a config you thought you kept.
- Flash an image whose sha256 differs from the server value.
- Flash an image whose signature is present but does not verify with the BYTE
  release key (`dcdb9655603fd9a0`), even if the sha256 matches.
- Gate halfway: a denial never leaves a partial image behind.
- Assume or change the root password.

### Coming from another OpenWrt

The installer itself is firmware-agnostic. Two things to expect:

- **Wipe, always.** Configs from another firmware family leave boxes without
  `wwand`, with an HTTPS listener, or with a dnsmasq that fights AdGuard Home,
  so nothing is carried over — not even between BYTE versions. Kernel version
  and package manager do not matter: everything goes through `sysupgrade -n`.
- **Board name.** The image declares `supported_devices: arcadyan,aw1000`. A
  build that reports something else (a vendor fork using `arcadyan,aw1000-v1`,
  for example) is rejected by that firmware's own image check. The installer
  reports it as `not supported by this image` and points at serial + U-Boot TFTP,
  rather than letting `sysupgrade` fail after the download.

### Resumed transfers

The installer uses `curl -C -` with `--retry 5 --retry-delay 2` and, when the
curl in use supports it, `--retry-all-errors`. The server answers `Range`
requests with `206`. If the mobile uplink stalls or the modem redials
mid-download, the next attempt continues from the byte it reached. The sha256
check is still the authority: a resumed file that does not match is downloaded
once more from zero and then refused.

## 3. Requirements on the device

- OpenWrt with `sysupgrade` and a sha256 tool (`sha256sum`, busybox `sha256sum`
  or `openssl`), plus one fetcher: `curl`, `uclient-fetch` or `wget`. All of
  these ship in 1.1.x, and stock OpenWrt has `wget` at minimum.
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
cat /etc/openwrt_release | grep -i byte      # BYTE 1.1.4
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
| pasted the command, no output at all, prompt back | old one-liner (`sh -c "$(curl ...)"`) with a failed download: the substitution is empty and `sh -c ""` exits 0 silently. Use `wget -qO /tmp/byte-i.sh … && sh /tmp/byte-i.sh` |
| banner printed, then nothing before the download | the prompt was answered with Enter, not `yes`, or stdin was not a terminal. Answer `yes`, run from an interactive SSH session, or add `-y` |
| downloaded, then aborted | the firmware refused the image: board name or config compat. The installer now runs `sysupgrade -T` first and prints the reason. A compat refusal is fixed by wiping (the default) |
| `refusing: this does not look like an Arcadyan AW1000` | the box does not report an AW1000 in `board_name`, model, DT `compatible` or `oem_name`. Use serial + U-Boot TFTP |
| `not licensed (http 403)` | request recorded, not approved yet. Re-run after approval |
| `not licensed` after a temporary window | licence expired. Ask for another window |
| gate passes, download stalls | client uplink or carrier. Re-run: it resumes |
| sha256 mismatch | image never flashed. Re-run; if it repeats, report the tag |
| `the image is not signed by dcdb9655603fd9a0` | the bytes did not come from the release key. Nothing was written. Report the tag to [@bytewrt](https://t.me/bytewrt); do not retry with `-F` |
| LuCI answers but pages look old | hard-refresh with **Ctrl+Shift+R** (LuCI caches panel JS) |
| no internet after boot | `ifstatus wan`, `ubus call network.interface.wan status`; interface is `wwand0` |

Never use `-F`, and never flash a foreign config over BYTE to "fix" a bad flash.
The serial console is the recovery path.

## Privacy

The gate sees: the device id, the tag requested, your country, timestamps, and
download/activation counters keyed by that id. It never sees traffic, IMEI,
ICCID, MSISDN or the SIM's identity. Licences are per device id, not per person.
Deleting a licence at the operator end removes the id, request and counters.
