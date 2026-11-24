import os
import stat
from pathlib import Path
import pytest
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from eth_account import Account
from backend.scripts.gen_keys import (
    compute_public_key_fingerprint,
    generate_auditor_keypair,
    generate_receipt_signer_key,
    generate_server_master_key,
)


def test_generate_auditor_keypair_and_oaep(tmp_path: Path):
    priv_path, pub_path, fp = generate_auditor_keypair(keys_dir=tmp_path)
    assert stat.S_IMODE(os.stat(priv_path).st_mode) == 0o600
    assert len(fp) == 64

    priv_key = serialization.load_pem_private_key(priv_path.read_bytes(), password=None)
    pub_key = serialization.load_pem_public_key(pub_path.read_bytes())
    assert isinstance(priv_key, rsa.RSAPrivateKey) and priv_key.key_size == 3072
    assert compute_public_key_fingerprint(pub_path.read_bytes()) == fp

    aes_key = os.urandom(32)
    ct = pub_key.encrypt(
        aes_key,
        padding.OAEP(mgf=padding.MGF1(hashes.SHA256()), algorithm=hashes.SHA256(), label=None),
    )
    pt = priv_key.decrypt(
        ct,
        padding.OAEP(mgf=padding.MGF1(hashes.SHA256()), algorithm=hashes.SHA256(), label=None),
    )
    assert pt == aes_key


def test_encrypted_private_key_with_passphrase(tmp_path: Path):
    priv_path, _, _ = generate_auditor_keypair(keys_dir=tmp_path, passphrase="Secret-2026!")
    with pytest.raises(TypeError):
        serialization.load_pem_private_key(priv_path.read_bytes(), password=None)
    priv_key = serialization.load_pem_private_key(priv_path.read_bytes(), password=b"Secret-2026!")
    assert priv_key.key_size == 3072


def test_master_and_signer_keys():
    mk = generate_server_master_key()
    assert mk.startswith("0x") and len(mk) == 66
    s_priv, s_addr = generate_receipt_signer_key()
    assert Account.from_key(s_priv).address == s_addr
