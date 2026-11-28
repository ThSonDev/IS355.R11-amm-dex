import httpx
from backend.app.config import settings

class IPFSClient:
    def __init__(self, api_url: str = settings.ipfs_api, gateway_url: str = settings.ipfs_gateway):
        self.api_url = api_url.rstrip("/")
        self.gateway_url = gateway_url.rstrip("/")

    async def get_version(self) -> str:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.post(f"{self.api_url}/api/v0/version")
            resp.raise_for_status()
            return resp.json().get("Version", "unknown")

    async def add_bytes(self, data: bytes, filename: str = "file.bin") -> str:
        params = {"cid-version": 1, "pin": "true"}
        files = {"file": (filename, data)}
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(f"{self.api_url}/api/v0/add", params=params, files=files)
            resp.raise_for_status()
            return resp.json()["Hash"]

    async def get_bytes(self, cid: str) -> bytes:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(f"{self.gateway_url}/ipfs/{cid}")
            resp.raise_for_status()
            return resp.content

ipfs_client = IPFSClient()
