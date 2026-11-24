from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict

ROOT_DIR = Path(__file__).resolve().parents[2]

class Settings(BaseSettings):
    rpc_url: str = "http://127.0.0.1:8545"
    chain_id: int = 31337
    deployments_path: str = str(ROOT_DIR / "deployments" / "anvil.json")
    ipfs_api: str = "http://127.0.0.1:5001"
    ipfs_gateway: str = "http://127.0.0.1:8080"

    receipt_issuer_private_key: str = ""
    server_master_key: str = ""
    auditor_public_key_path: str = str(ROOT_DIR / "keys" / "auditor_public.pem")
    pinata_jwt: str = ""

    model_config = SettingsConfigDict(
        env_file=str(ROOT_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

settings = Settings()
