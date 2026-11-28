#!/bin/sh
# ByteHelper footer fix, kept for BYTE 1.2.0 only.
# 1.3.x ships luci-app-bytehelper r3, which removes the extra LuCI footer in
# the views themselves. This script exits without touching anything on 1.3.x.
# Run as root on the router.
#
#   wget -qO /tmp/bhfix.sh https://raw.githubusercontent.com/Ace1337z/AW1000_BYTE_NSS/main/scripts/bytehelper-fix.sh && sh /tmp/bhfix.sh
#
set -eu
REL="$(sed -n "s/^DISTRIB_RELEASE='\(.*\)'$/\1/p" /etc/openwrt_release 2>/dev/null | head -1)"
case "$REL" in
	1.3.*)
		echo "BYTE ${REL:-1.3.x} already carries the ByteHelper footer fix; nothing to do."
		exit 0
		;;
esac

RULE='#view > .bytehelper-page ~ .cbi-page-actions { display: none !important; }'
MEDIA="$(uci -q get luci.main.mediaurlbase || true)"
[ -n "$MEDIA" ] || MEDIA=/luci-static/vantage
DIR="/www${MEDIA}"

n=0
set -- "$DIR"/*.css
[ -f "$1" ] || set -- /www/luci-static/*/cascade.css

for f in "$@"; do
	[ -f "$f" ] || continue
	if grep -q 'bytehelper-page ~ .cbi-page-actions' "$f" 2>/dev/null; then
		continue
	fi
	cp "$f" "$f.bytehelper.bak" 2>/dev/null || true
	printf '\n/* ByteHelper: hide the CBI footer */\n%s\n' "$RULE" >>"$f"
	n=$((n + 1))
done

rm -f /tmp/luci-indexcache*
/etc/init.d/uhttpd restart >/dev/null 2>&1
echo "ByteHelper footer fix: $n stylesheet(s) updated."
echo "Hard-refresh LuCI with Ctrl+Shift+R."
