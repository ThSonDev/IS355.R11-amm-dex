import argparse
import hashlib
import os
import secrets
from pathlib import Path
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from eth_account import Account

ROOT_DIR = Path(__file__).resolve().parents[2]
DEFAULT_KEYS_DIR = ROOT_DIR / "keys"


def _write_secure_file(path: Path, data: bytes, mode: int) -> None:
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, mode)
    try:
        os.write(fd, data)
    finally:
        os.close(fd)
    os.chmod(path, mode)


def compute_public_key_fingerprint(pub_pem: bytes) -> str:
    pub_key = serialization.load_pem_public_key(pub_pem)
    der_bytes = pub_key.public_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    return hashlib.sha256(der_bytes).hexdigest()


def generate_auditor_keypair(
    keys_dir: Path = DEFAULT_KEYS_DIR,
    force: bool = False,
    passphrase: str | None = None,
) -> tuple[Path, Path, str]:
    keys_dir.mkdir(parents=True, exist_ok=True)
    priv_path = keys_dir / "auditor_private.pem"
    pub_path = keys_dir / "auditor_public.pem"

    if (priv_path.exists() or pub_path.exists()) and not force:
        raise FileExistsError(f"Khoa da ton tai tai {keys_dir}. Dung --force de ghi de.")

    private_key = rsa.generate_private_key(public_exponent=65537, key_size=3072)
    enc_algo = (
        serialization.BestAvailableEncryption(passphrase.encode("utf-8"))
        if passphrase
        else serialization.NoEncryption()
    )

    priv_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=enc_algo,
    )
    pub_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )

    _write_secure_file(priv_path, priv_pem, 0o600)
    _write_secure_file(pub_path, pub_pem, 0o644)
    return priv_path, pub_path, compute_public_key_fingerprint(pub_pem)


def generate_server_master_key() -> str:
    return "0x" + secrets.token_hex(32)


def generate_receipt_signer_key() -> tuple[str, str]:
    acct = Account.create()
    return acct.key.hex(), acct.address


def main() -> None:
    parser = argparse.ArgumentParser(description="Sinh khoa RSA-3072 Auditor & ECDSA Signer")
    parser.add_argument("--keys-dir", type=Path, default=DEFAULT_KEYS_DIR)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--passphrase", type=str, default=os.getenv("AUDITOR_KEY_PASSPHRASE"))
    args = parser.parse_args()

    priv_path, pub_path, fp = generate_auditor_keypair(args.keys_dir, args.force, args.passphrase)
    master_key = generate_server_master_key()
    signer_priv, signer_addr = generate_receipt_signer_key()

    print(f"[OK] Private Key: {priv_path}")
    print(f"[OK] Public Key : {pub_path}")
    print(f"[OK] Fingerprint: {fp}")
    print(f"[OK] Signer Addr: {signer_addr}")
    print(f"SERVER_MASTER_KEY={master_key}")
    print(f"RECEIPT_SIGNER_PRIVATE_KEY={signer_priv}")
    print(f"AUDITOR_PUBKEY_FINGERPRINT={fp}")


if __name__ == "__main__":
    main()
