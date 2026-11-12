#!/usr/bin/env bash
# Kiểm tra môi trường dev: công cụ, phiên bản, cổng. Thoát khác 0 nếu có FAIL.
cd "$(dirname "$0")/.." || exit 1
export PATH="$PATH:$HOME/.foundry/bin"
PORTS="${DOCTOR_PORTS:-8545 5001 8080 8000 5173}"
fail=0
ok()  { echo "OK   $1"; }
bad() { echo "FAIL $1"; fail=1; }

for t in git forge anvil cast; do
  command -v "$t" >/dev/null && ok "$t: $("$t" --version 2>&1 | head -1)" || bad "$t chưa cài (docs/SETUP.md mục 2)"
done

# Node: so major với .nvmrc
want=$(tr -d 'v\n ' < .nvmrc)
if command -v node >/dev/null; then
  have=$(node -v | tr -d v)
  [ "${have%%.*}" = "${want%%.*}" ] && ok "node $have" || bad "node $have, cần major $want (.nvmrc)"
else bad "node chưa cài, cần major $want"; fi

# Python: so major.minor với .python-version
want=$(tr -d '\n ' < .python-version)
if command -v python3 >/dev/null; then
  have=$(python3 -c 'import sys;print("%d.%d"%sys.version_info[:2])')
  [ "$have" = "${want%.*.*}" ] || [ "$have" = "$want" ] && ok "python3 $have" || bad "python3 $have, cần $want (.python-version)"
else bad "python3 chưa cài, cần $want"; fi

command -v ipfs >/dev/null && ok "ipfs $(ipfs version -n 2>&1)" || bad "ipfs (Kubo) chưa cài"

for p in $PORTS; do
  if (exec 3<>"/dev/tcp/127.0.0.1/$p") 2>/dev/null; then bad "cổng $p đang bị chiếm"; else ok "cổng $p trống"; fi
done
exit $fail
