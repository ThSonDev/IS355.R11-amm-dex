#!/usr/bin/env python3
"""Build deployments/<chain>.json (address + ABI per contract). Stdlib only.

  export-deployments.py --chain anvil|sepolia     real export after Deploy.s.sol
  export-deployments.py --example                 fake addresses -> deployments/example.json
  export-deployments.py --check FILE              validate a deployments file
Inputs (real export): deployments/<chainId>.addresses.json (LABEL -> address, written by
Deploy.s.sol), contracts/out/ (ABIs), contracts/broadcast/Deploy.s.sol/<chainId>/run-latest.json.
"""
import argparse, json, re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHAINS = {"anvil": 31337, "sepolia": 11155111}
# label -> (implementation artifact, interface artifact used by --example/--interfaces)
ARTIFACTS = {
    "TokenA": ("TestToken", "ITestToken"),
    "TokenB": ("TestToken", "ITestToken"),
    "AMMPair": ("AMMPair", "IAMMPair"),
    "AMMRouter": ("AMMRouter", "IAMMRouter"),
    "DEXToken": ("DEXToken", "DEXToken"),
    "StakingRewards": ("StakingRewards", "IStakingRewards"),
    "DEXGovernor": ("DEXGovernor", "DEXGovernor"),
    "Timelock": ("TimelockController", "TimelockController"),
    "DEXRegistry": ("DEXRegistry", "IDEXRegistry"),
}
# Default Anvil accounts #0-#5 (from `anvil` output; ARCHITECTURE 4.8 roles)
ANVIL_ACCOUNTS = {
    "Admin": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "LP": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "Trader": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    "Community": "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
    "Auditor": "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
    "Backend": "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
}
ADDR = re.compile(r"^0x[0-9a-fA-F]{40}$")


def fail(msg):
    sys.exit(f"error: {msg}")


def load(path, hint):
    if not path.is_file():
        fail(f"missing {path.relative_to(ROOT)} ({hint})")
    return json.loads(path.read_text())


def abi_of(name):
    hits = list((ROOT / "contracts/out").glob(f"*/{name}.json"))
    if len(hits) != 1:
        fail(f"artifact {name}.json not found exactly once in contracts/out ({len(hits)} found); run `forge build`")
    return json.loads(hits[0].read_text())["abi"]


def build(chain_id, addresses, deploy_block, commit, accounts, use_interfaces):
    missing = [l for l in ARTIFACTS if l not in addresses]
    if missing:
        fail(f"addresses file lacks labels: {', '.join(missing)}")
    contracts = {l: {"address": addresses[l], "abi": abi_of(ARTIFACTS[l][1 if use_interfaces else 0])} for l in ARTIFACTS}
    return {"chainId": chain_id, "deployBlock": deploy_block, "commit": commit, "contracts": contracts, "accounts": accounts}


def check(path):
    d = load(Path(path), "file to check")
    errs = []
    for k in ("chainId", "deployBlock", "commit", "contracts", "accounts"):
        if k not in d:
            errs.append(f"missing field {k}")
    for l in ARTIFACTS:
        c = d.get("contracts", {}).get(l)
        if not c:
            errs.append(f"missing contract {l}")
            continue
        if not ADDR.match(str(c.get("address", ""))):
            errs.append(f"{l}: bad address")
        if not isinstance(c.get("abi"), list) or not c["abi"]:
            errs.append(f"{l}: abi empty")
    for r, a in d.get("accounts", {}).items():
        if not ADDR.match(str(a)):
            errs.append(f"account {r}: bad address")
    return errs


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--chain", choices=CHAINS)
    g.add_argument("--example", action="store_true")
    g.add_argument("--check", metavar="FILE")
    ap.add_argument("--interfaces", action="store_true", help="take ABIs from interfaces (implies incomplete ABIs)")
    a = ap.parse_args()

    if a.check:
        errs = check(a.check)
        print("\n".join(errs) if errs else f"OK {a.check}")
        sys.exit(1 if errs else 0)

    if a.example:
        addrs = {l: "0x" + f"{i:040x}" for i, l in enumerate(ARTIFACTS, 1)}
        out = ROOT / "deployments/example.json"
        data = build(31337, addrs, 1, "0" * 40, ANVIL_ACCOUNTS, True)
    else:
        cid = CHAINS[a.chain]
        addrs = load(ROOT / f"deployments/{cid}.addresses.json", "written by Deploy.s.sol")
        run = load(ROOT / f"contracts/broadcast/Deploy.s.sol/{cid}/run-latest.json", "run forge script with --broadcast")
        blocks = [int(r["blockNumber"], 16) for r in run.get("receipts", [])]
        if not blocks:
            fail("run-latest.json has no receipts")
        commit = subprocess.check_output(["git", "-C", str(ROOT), "rev-parse", "HEAD"], text=True).strip()
        out = ROOT / f"deployments/{a.chain}.json"
        data = build(cid, addrs, min(blocks), commit, ANVIL_ACCOUNTS if a.chain == "anvil" else {}, a.interfaces)
    out.write_text(json.dumps(data, indent=2) + "\n")
    print(f"wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
