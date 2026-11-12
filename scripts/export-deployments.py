#!/usr/bin/env python3
"""Build deployments/<chain>.json (address + ABI per contract). Stdlib only.

  export-deployments.py --chain anvil|sepolia     real export after Deploy.s.sol
  export-deployments.py --example                 fake addresses -> deployments/example.json
                                                  (runs forge build itself; needs only a fresh clone)
  export-deployments.py --check FILE [--require-all]   validate a deployments file
Inputs (real export): deployments/<chainId>.addresses.json (LABEL -> address, written by
Deploy.s.sol), contracts/out/ (ABIs), contracts/broadcast/Deploy.s.sol/<chainId>/run-latest.json.
"""
import argparse, json, os, re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHAINS = {"anvil": 31337, "sepolia": 11155111}
# label -> (implementation artifact for the real export, artifacts merged for --example/--interfaces).
# Interface mode merges OZ interfaces so inherited ERC20/AccessControl/Governor functions are present.
ARTIFACTS = {
    "TokenA": ("TestToken", ["ITestToken", "IERC20Metadata"]),
    "TokenB": ("TestToken", ["ITestToken", "IERC20Metadata"]),
    "AMMPair": ("AMMPair", ["IAMMPair", "IERC20Metadata", "IAccessControl"]),
    "AMMRouter": ("AMMRouter", ["IAMMRouter"]),
    "DEXToken": ("DEXToken", ["IERC20Metadata", "IERC20Permit", "IERC5805"]),
    "StakingRewards": ("StakingRewards", ["IStakingRewards", "IAccessControl"]),
    "DEXGovernor": ("DEXGovernor", ["IGovernor"]),
    "Timelock": ("TimelockController", ["TimelockController"]),
    "DEXRegistry": ("DEXRegistry", ["IDEXRegistry", "IAccessControl"]),
}
# OZ sources compiled by path for interface mode (our own src/ is built too)
OZ = "lib/openzeppelin-contracts/contracts/"
OZ_PATHS = [OZ + p for p in (
    "token/ERC20/extensions/IERC20Metadata.sol", "token/ERC20/extensions/IERC20Permit.sol",
    "interfaces/IERC5805.sol", "access/IAccessControl.sol", "governance/IGovernor.sol",
    "governance/TimelockController.sol")]
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


def merged_abi(names):
    """Concatenate ABIs, de-duplicated by (type, name, input types)."""
    seen, out = set(), []
    for n in names:
        for e in abi_of(n):
            key = (e["type"], e.get("name"), tuple(i["type"] for i in e.get("inputs", [])))
            if key not in seen:
                seen.add(key)
                out.append(e)
    return out


def build_oz():
    try:
        subprocess.run(["forge", "build", "src", *OZ_PATHS], cwd=ROOT / "contracts", check=True, stdout=subprocess.DEVNULL,
                       env={**os.environ, "PATH": os.environ["PATH"] + ":" + str(Path.home() / ".foundry/bin")})
    except (OSError, subprocess.CalledProcessError) as e:
        fail(f"forge build failed ({e}); see docs/SETUP.md section 2")


def build(chain_id, addresses, deploy_block, commit, accounts, use_interfaces):
    unknown = [l for l in addresses if l not in ARTIFACTS]
    bad = [l for l, a in addresses.items() if not ADDR.match(str(a))]
    if unknown or bad:
        fail(f"addresses file: unknown labels {unknown}, malformed addresses {bad}")
    for l in ARTIFACTS:
        if l not in addresses:
            print(f"warning: no address for {l}, left out", file=sys.stderr)
    contracts = {l: {"address": a, "abi": merged_abi(ARTIFACTS[l][1]) if use_interfaces else abi_of(ARTIFACTS[l][0])}
                 for l, a in addresses.items()}
    return {"chainId": chain_id, "deployBlock": deploy_block, "commit": commit, "contracts": contracts, "accounts": accounts}


def check(path, require_all):
    d = load(Path(path), "file to check")
    errs = []
    for k in ("chainId", "deployBlock", "commit", "contracts", "accounts"):
        if k not in d:
            errs.append(f"missing field {k}")
    present = d.get("contracts", {})
    errs += [f"unknown contract {l}" for l in present if l not in ARTIFACTS]
    for l in (ARTIFACTS if require_all else present):
        c = present.get(l)
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
    ap.add_argument("--require-all", action="store_true", help="with --check: all 9 labels must be present")
    ap.add_argument("--interfaces", action="store_true", help="take ABIs from interfaces (implies incomplete ABIs)")
    a = ap.parse_args()

    if a.check:
        errs = check(a.check, a.require_all)
        print("\n".join(errs) if errs else f"OK {a.check}")
        sys.exit(1 if errs else 0)

    if a.example:
        build_oz()
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
        if a.interfaces:
            build_oz()
        out = ROOT / f"deployments/{a.chain}.json"
        data = build(cid, addrs, min(blocks), commit, ANVIL_ACCOUNTS if a.chain == "anvil" else {}, a.interfaces)
    out.write_text(json.dumps(data, indent=2) + "\n")
    print(f"wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
