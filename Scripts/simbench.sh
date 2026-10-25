#!/bin/zsh
# Usage: Scripts/simbench.sh <udid> <outdir> <seconds> scene...  Runs -bench per scene on a sim, copies JSON.
UDID=$1; OUT=$2; SECS=$3; shift 3
APP=${APP:-/private/tmp/claude-501/-Users-hunter-Dev-RealForge/bf7ea6d8-3c91-4983-ba84-ad5e11edae7f/scratchpad/dd/Build/Products/Release-xrsimulator/RealityHDDemo.app}
BID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' $APP/Info.plist)
xcrun simctl install $UDID $APP; mkdir -p $OUT
for s in "$@"; do
  C=$(xcrun simctl get_app_container $UDID $BID data)/Library/Caches/bench; rm -f $C/$s.json
  xcrun simctl terminate $UDID $BID 2>/dev/null
  xcrun simctl launch $UDID $BID -scene $s -bench $SECS -dolly 1.4 -hideMenu YES >/dev/null
  for i in {1..240}; do [[ -f $C/$s.json ]] && break; sleep 1; done
  cp $C/$s.json $OUT/ 2>/dev/null && python3 - $OUT/$s.json <<'PY'
import json,sys;d=json.load(open(sys.argv[1]));f=d["frames"];S=d["samples"]
mx=lambda k:int(max([x[k] for x in S] or [0]))
print(f'{d["scene"]:20} build {d["buildMs"]:6}ms loadStall {int(d["loadStall"]["max"]):4} p99 {f["p99"]:.1f} max {f["max"]:.0f} o25 {int(f["over25"])} vtris {mx("vtris")//1000}k vdraws {mx("vdraws")} stris {mx("stris")//1000}k')
PY
  [[ -f $OUT/$s.json ]] || echo "$s TIMEOUT"
done
xcrun simctl terminate $UDID $BID 2>/dev/null
