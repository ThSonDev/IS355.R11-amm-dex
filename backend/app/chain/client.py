from web3 import Web3
from eth_account import Account
from backend.app.config import settings

def get_web3() -> Web3:
    return Web3(Web3.HTTPProvider(settings.rpc_url, request_kwargs={"timeout": 5}))

def check_rpc_status() -> dict:
    w3 = get_web3()
    if not w3.is_connected():
        return {"connected": False, "block_number": None, "issuer_balance_eth": None}
    
    block_number = w3.eth.block_number
    balance_eth = None
    key = settings.receipt_issuer_private_key
    if key and not key.startswith("<"):
        try:
            acct = Account.from_key(key)
            bal_wei = w3.eth.get_balance(acct.address)
            balance_eth = str(w3.from_wei(bal_wei, "ether"))
        except Exception:
            balance_eth = "invalid_key"

    return {
        "connected": True,
        "chain_id": w3.eth.chain_id,
        "block_number": block_number,
        "issuer_balance_eth": balance_eth,
    }
