#!/bin/bash
# Frame-timing run on a connected Android device using a self-playing bot.
# usage: tool/perf.sh <label> [seconds] [extra --dart-define flags...]
# Builds a profile APK with PERF_LOG + PERF_GOD (bot plays, cannot die).
set -e
LABEL=${1:-run}; SECS=${2:-120}; shift 2 2>/dev/null || true
P=com.spudbyte.one_bullet
D=${DEVICE:-$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')}
A="adb -s $D shell"
OUT=$(dirname "$0")/perf-out; mkdir -p "$OUT"
flutter build apk --profile --dart-define=PERF_LOG=true --dart-define=PERF_GOD=true "$@" >/dev/null
adb -s "$D" install -r build/app/outputs/flutter-apk/app-profile.apk >/dev/null
$A am force-stop $P; adb -s "$D" logcat -c
$A monkey -p $P -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 7
$A input tap 540 1680
sleep "$SECS"
adb -s "$D" logcat -d -s flutter | grep PERF | sed 's/.*PERF//' > "$OUT/$LABEL.txt"
python3 - "$OUT/$LABEL.txt" <<'PY'
import re, sys
rows = [l for l in open(sys.argv[1]) if 'frames=' in l][1:]
if not rows: sys.exit('no PERF lines')
g = lambda k, l, i=0: float(re.search(k + r'[^=]*=([\d.]+)/([\d.]+)/([\d.]+)', l).group(i + 1))
n = sum(int(re.search(r'frames=(\d+)', l).group(1)) for l in rows)
slow = sum(int(re.search(r'>16ms=(\d+)', l).group(1)) for l in rows)
bad = sum(int(re.search(r'>33ms=(\d+)', l).group(1)) for l in rows)
avg = lambda v: sum(v) / len(v)
print(f"{sys.argv[1]}: {n} frames; build p50 {avg([g('build',l) for l in rows]):.1f} raster p50 {avg([g('raster',l) for l in rows]):.1f} total p99 {avg([g('total',l,1) for l in rows]):.1f}ms; >16.7ms {100*slow/n:.1f}%  >33ms {100*bad/n:.2f}%")
PY
