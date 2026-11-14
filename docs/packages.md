# BYTE 1.1.4 package set

345 packages installed on the running AW1000 (`apk info`, 1.1.4 build
`r0-d6c8942`). This is the whole list, grouped by what it does. Nothing here is
"installed but broken": every group below has a UI page or a CLI that uses it.

```
$ apk info | wc -l
345
```

---

## Platform, kernel and NSS offload

`kernel`, `kmod-qca-nss-drv`, `kmod-qca-nss-drv-bridge-mgr`,
`kmod-qca-nss-drv-igs`, `kmod-qca-nss-drv-mirror`, `kmod-qca-nss-drv-netlink`,
`kmod-qca-nss-drv-pppoe`, `kmod-qca-nss-drv-qdisc`, `kmod-qca-nss-ecm`,
`kmod-qca-mcs`, `kmod-qca-ppe-nss`, `kmod-qcom-qmi-helpers`, `kmod-qmi_wwan_q`,
`kmod-rmnet`, `kmod-qrtr`, `kmod-qrtr-smd`, `nss-firmware`,
`nss-firmware-ipq807x`, `nss-tools`, `nssinfo`, `nssqos`, `libnl-nss`,
`wwand-datapath-rmnet_nss`, `libudebug`

Kernel **6.18.55**. NSS firmware **12.5**, 1 GB memory profile. EDMA on every
wired port, `CONFIG_NSS_DRV_PPE_VP_ENABLE=n`, `rmnet_rx` nexthop on core 1.

## Wi-Fi and board support

`ath11k-firmware-ipq8074`, `ipq-wifi-arcadyan_aw1000`, `kmod-ath`,
`kmod-ath11k`, `kmod-ath11k-ahb`, `kmod-cfg80211`, `kmod-mac80211`,
`hostapd-common`, `wpad-openssl`, `wifi-scripts`, `wireless-regdb`, `iw`,
`libiwinfo-data`, `libiwinfo20230701`, `kmod-gpio-button-hotplug`,
`kmod-gpio-nxp-74hc164`, `kmod-leds-gpio`, `kmod-hwmon-core`, `kmod-i2c-core`,
`kmod-spi-gpio`, `kmod-spi-bitbang`, `aw1000-defaults`

Two radios, Wi-Fi 6, 2.4 GHz + 5 GHz. `wpad-openssl` covers WPA2-PSK and
WPA3-SAE.

## Modem, USB and RJ11 voice

`wwand`, `wwand-qmi`, `kmod-usb-net`, `kmod-usb-serial`,
`kmod-usb-serial-option`, `kmod-usb-serial-wwan`, `kmod-usb-wdm`,
`kmod-usb-common`, `kmod-usb-core`, `kmod-usb-dwc3`, `kmod-usb-dwc3-qcom`,
`kmod-usb-roles`, `kmod-usb-xhci-hcd`, `kmod-usb3`, `kmod-usb-storage`,
`kmod-usb-storage-uas`, `kmod-scsi-core`, `kmod-mii`, `kmod-slhc`,
`awvoice-phoned`, `kmod-awvoice-fxs`, `qmodem-sipd`, `sms-tool`, `sms-tool_q`,
`kmod-reed-solomon`

`wwand` is the single AT and dial owner. QModem is pinned to `/dev/ttyUSB3`,
awvoice owns `/dev/ttyUSB2`, so the voice and data paths never collide.

## Firewall, NAT and QoS

`firewall4`, `nftables-json`, `bcp38`, `kmod-nf-conntrack`,
`kmod-nf-conntrack-netlink`, `kmod-nf-flow`, `kmod-nf-log`, `kmod-nf-log6`,
`kmod-nf-nat`, `kmod-nf-reject`, `kmod-nf-reject6`, `kmod-nf-socket`,
`kmod-nf-tproxy`, `kmod-nfnetlink`, `kmod-nft-core`, `kmod-nft-fib`,
`kmod-nft-nat`, `kmod-nft-offload`, `kmod-nft-socket`, `kmod-nft-tproxy`,
`kmod-ifb`, `kmod-sched`, `kmod-sched-core`, `kmod-sched-cake`, `kmod-tcp-bbr`,
`tc-tiny`, `sqm-scripts`, `sqm-scripts-nss`, `nssqos`

nftables only. `sqm-scripts-nss` puts shaping on the NSS cores instead of the
CPU.

## Proxy, VPN and tunnelling

`xray-core`, `chinadns-ng`, `dns2socks`, `dns2tcp`, `microsocks`,
`amneziawg-tools`, `kmod-amneziawg`, `kmod-udptunnel4`, `kmod-udptunnel6`,
`kmod-tun`, `tcping`, `kmod-crypto-acompress`, `kmod-crypto-aead`,
`kmod-crypto-ccm`, `kmod-crypto-cmac`, `kmod-crypto-crc32c`, `kmod-crypto-ctr`,
`kmod-crypto-gcm`, `kmod-crypto-geniv`, `kmod-crypto-gf128`,
`kmod-crypto-ghash`, `kmod-crypto-hash`, `kmod-crypto-hmac`,
`kmod-crypto-kpp`, `kmod-crypto-lib-chacha20`,
`kmod-crypto-lib-chacha20poly1305`, `kmod-crypto-lib-curve25519`,
`kmod-crypto-lib-poly1305`, `kmod-crypto-manager`, `kmod-crypto-michael-mic`,
`kmod-crypto-null`, `kmod-crypto-rng`, `kmod-crypto-seqiv`, `kmod-crypto-sha3`,
`kmod-crypto-sha512`

PassWall2 with Xray is the default proxy. PassWall v1 4.66-8 is vendored and
disabled. AmneziaWG is installed, configured and off.

## DNS and IPv6

`dnsmasq-full`, `odhcp6c`, `odhcpd-ipv6only`, `resolveip`, `getrandom`,
`urandom-seed`, `urngd`

`dnsmasq-full` gives `filter_aaaa`, per-source DNS and the `:54` move used by the
AdGuard Home chain.

## LuCI and web serving

`luci`, `luci-base`, `luci-compat`, `luci-light`, `luci-lua-runtime`,
`luci-mod-admin-full`, `luci-mod-network`, `luci-mod-status`, `luci-mod-system`,
`luci-lib-base`, `luci-lib-ip`, `luci-lib-jsonc`, `luci-lib-nixio`,
`luci-lib-uqr`, `luci-lib-chartjs`, `luci-proto-ipv6`, `luci-proto-ppp`,
`luci-proto-wwand`, `luci-proto-amneziawg`, `luci-theme-vantage`,
`luci-theme-bootstrap`, `luci-ssl-openssl`, `uhttpd`, `uhttpd-mod-ubus`,
`rpcd`, `rpcd-mod-file`, `rpcd-mod-iwinfo`, `rpcd-mod-luci`, `rpcd-mod-rrdns`,
`rpcd-mod-ucode`, `liblucihttp-lua`, `liblucihttp-ucode`, `liblucihttp0`

Vantage is the theme; Bootstrap stays as fallback. `luci-ssl-openssl` is present
for the packages that link against it, but no HTTPS listener is configured.

## Ucode runtime and SSH

`ucode`, `ucode-mod-digest`, `ucode-mod-fs`, `ucode-mod-html`, `ucode-mod-log`,
`ucode-mod-lua`, `ucode-mod-nl80211`, `ucode-mod-rtnl`, `ucode-mod-struct`,
`ucode-mod-ubus`, `ucode-mod-uci`, `ucode-mod-uloop`, `libucode20230711`,
`libblobmsg-json20260721`, `uclient-fetch`, `libuclient20201210`,
`openssh-server`, `openssh-keygen`, `openssh-moduli`,
`openssh-sftp-server`

LuCI's ucode views run on this set; OpenSSH is the only remote shell in the
image (dropbear is not installed).

## LuCI applications

`luci-app-9router`, `luci-app-aw1000-modem`, `luci-app-awvoice`,
`luci-app-bcp38`, `luci-app-byte`, `luci-app-filemanager`, `luci-app-firewall`,
`luci-app-modeminfo`, `luci-app-netstat`, `luci-app-nlbwmon`, `luci-app-nss`,
`luci-app-nssqos`, `luci-app-package-manager`, `luci-app-passwall`,
`luci-app-passwall2`, `luci-app-qmodem-ttlfw4`, `luci-app-ramfree`,
`luci-app-sqm`, `luci-app-vantage`, `luci-app-vnstat2`, `luci-app-wwand`

Twenty-one app packages, every one of them reachable from the menu. See
[apps.md](apps.md) for the page-by-page tour.

## Monitoring and traffic accounting

`vnstat2`, `vnstati2`, `nlbwmon`, `libgd`, `libpng`, `libjpeg-turbo`, `libwebp`

vnStat 2.13 (SQLite) for historical graphs, nlbwmon for per-host and
per-protocol accounting.

## Storage, filesystems and flash

`block-mount`, `fstools`, `e2fsprogs`, `libext2fs2`, `libe2p2`, `libcomerr0`,
`libblkid1`, `blkid`, `libuuid1`, `losetup`, `mtd`, `ubi-utils`,
`uboot-envtools`, `fwtool`, `kmod-fs-ext4`, `kmod-fs-exfat`, `kmod-fs-ntfs3`,
`kmod-fs-vfat`, `kmod-nls-base`, `kmod-nls-cp437`, `kmod-nls-iso8859-1`,
`kmod-nls-utf8`, `kmod-lib-crc-ccitt`, `kmod-lib-crc16`, `kmod-lib-xxhash`

The **File Manager** app uses this set for USB disks and attached storage.

## Crypto, TLS and certificates

`libopenssl3`, `libopenssl-conf`, `libopenssl-legacy`, `libopenssl-oqsprovider`,
`liboqs`, `openssl-util`, `apk-openssl`, `ca-bundle`, `libustream-openssl20201210`,
`libmbedtls21`, `libnettle8`, `libgmp10`, `usign`, `openwrt-keyring`,
`libcurl4`, `libnghttp2-14`, `libss2`

## System, init and base utilities

`base-files`, `busybox`, `procd`, `procd-seccomp`, `procd-ujail`, `ubox`,
`ubus`, `ubusd`, `uci`, `libuci20250120`, `libubus20260925`,
`libubus-lua`, `libuci-lua`, `libubox20260721`, `libjson-c5`,
`libjson-script20260721`, `jshn`, `jsonfilter`, `jansson4`, `netifd`, `ppp`,
`ppp-mod-pppoe`, `kmod-ppp`, `kmod-pppoe`, `kmod-pppox`, `kmod-nf-conntrack`,
`logd`, `cgi-io`, `libstdcpp6`, `libgcc1`, `libatomic1`, `libc`,
`libpthread`, `librt`, `zlib`, `kmod-lib-zlib-deflate`,
`kmod-lib-zlib-inflate`, `kmod-lib-zstd`, `kmod-lib-textsearch`, `libelf1`,
`libbpf1`, `libmnl0`, `libnfnetlink0`, `libnetfilter-conntrack3`, `libnftnl11`,
`libnl-tiny1`, `libsmartcols1`, `libncurses6`, `terminfo`, `liblua5.1.5`,
`lua`, `libsqlite3-0`, `libpj`, `libpjlib-util`, `libpjmedia`, `libpjnath`,
`libpjsip`, `libpjsip-simple`, `libpjsip-ua`, `udp-broadcast-relay-redux`

## CLI tools

`btop`, `htop`, `iperf3`, `libiperf3`, `curl`, `ethtool`, `ip-full`,
`ip-bridge`, `unzip`, `coreutils`, `coreutils-base64`, `coreutils-nohup`,
`qrencode`, `libqrencode`, `tcping`, `kmod-dummy`, `kmod-inet-diag`,
`kmod-pstore`, `kmod-ramoops`, `kmod-thermal`, `zram-swap`, `kmod-zram`

`kmod-dummy`, `kmod-inet-diag` (`ss -e`) and `kmod-tun` were restored in 1.1.3
so CLI tooling and diagnostics do not fail on a missing module.

## AdGuard Home helper

`agh-passwd`

A 20 KB static binary linked against libxcrypt. The BYTE panel uses it to write a
bcrypt hash into AdGuard Home's `users:` list without Python, Perl, `htpasswd`
or `mkpasswd`. AdGuard Home itself is installed on demand from the BYTE panel —
it is not part of the base image.

---

## What is deliberately missing

| Dropped | Why |
| --- | --- |
| `tailscale` | size; not needed on a CPE |
| Wake-on-LAN | no use on this board |
| Dynamic DNS | provider-specific, adds a daemon |
| WireGuard | AmneziaWG supersedes it here |
| `uqmi`, `quectel-cm`, `kmod-usb-net-qmi-wwan` | would fight `wwand` for the modem |
| `qmodem` AT owner | same: one AT owner only |
| Python, Perl | size; `agh-passwd` covers the one need |
| `v2ray-geoip`, `v2ray-geosite` | install on demand for `geoip:` rules |
| vendor Si3226x DSP blob | removed with the old `fxsd` stack |
