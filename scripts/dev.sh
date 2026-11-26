#!/usr/bin/env bash
# dev.sh v1: Anvil + deploy/seed (only when the chain has no deployment yet) + deployments/anvil.json.
# Usage: scripts/dev.sh [--fresh]     --fresh drops the Anvil state and deploys again.
# Env:   RPC_URL (default http://127.0.0.1:8545), MNEMONIC (read by the forge scripts).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$PATH:$HOME/.foundry/bin"

RPC_URL="${RPC_URL:-http://127.0.0.1:8545}"
PORT="${RPC_URL##*:}"
STATE=.anvil/state.json
ADDRS=deployments/31337.addresses.json

for t in anvil forge cast python3; do
  command -v "$t" >/dev/null || { echo "error: $t not found, see docs/SETUP.md section 2" >&2; exit 1; }
done
if cast chain-id --rpc-url "$RPC_URL" >/dev/null 2>&1; then
  echo "error: something already answers on $RPC_URL (stop it first, see scripts/doctor.sh)" >&2; exit 1
fi

if [ "${1:-}" = "--fresh" ]; then
  rm -rf .anvil "$ADDRS" deployments/anvil.json
  echo "State dropped. Reset the MetaMask account (Settings > Advanced > Clear activity tab data)."
elif [ -n "${1:-}" ]; then
  echo "usage: scripts/dev.sh [--fresh]" >&2; exit 2
fi
mkdir -p .anvil

anvil --port "$PORT" --block-time 2 --state "$STATE" >.anvil/anvil.log 2>&1 &
ANVIL=$!
# SIGINT makes Anvil dump its state before exiting
trap 'kill -INT "$ANVIL" 2>/dev/null; wait "$ANVIL" 2>/dev/null || true' EXIT INT TERM
for _ in $(seq 50); do
  cast chain-id --rpc-url "$RPC_URL" >/dev/null 2>&1 && break
  kill -0 "$ANVIL" 2>/dev/null || { echo "error: anvil exited, see .anvil/anvil.log" >&2; exit 1; }
  sleep 0.2
done

# Deployed already? The addresses file must exist and the pair must have code on this chain.
deployed=0
if [ -f "$ADDRS" ]; then
  pair=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["AMMPair"])' "$ADDRS")
  [ "$(cast code "$pair" --rpc-url "$RPC_URL")" != "0x" ] && deployed=1
fi
if [ "$deployed" = 0 ]; then
  (cd contracts && forge script script/Deploy.s.sol --rpc-url "$RPC_URL" --broadcast >/dev/null \
    && forge script script/Seed.s.sol --rpc-url "$RPC_URL" --broadcast >/dev/null)
  echo "Deployed and seeded."
else
  echo "Already deployed, skipping deploy and seed."
fi

python3 scripts/export-deployments.py --chain anvil
echo "Anvil running on $RPC_URL (Ctrl+C to stop; state saved to $STATE)."
wait "$ANVIL"
