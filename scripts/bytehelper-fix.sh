#!/bin/sh
# ByteHelper 1.2.0: hide LuCI's Save / Save & Apply / Reset footer on the
# ByteHelper pages. Safe to re-run. Run as root on the router.
#
#   wget -qO /tmp/bhfix.sh https://raw.githubusercontent.com/Ace1337z/AW1000_BYTE_NSS/main/scripts/bytehelper-fix.sh && sh /tmp/bhfix.sh
#
set -eu

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
