import pytest
from fastapi.testclient import TestClient
from backend.app.main import app
from backend.app.ipfs.client import ipfs_client

client = TestClient(app)

def test_health_endpoint():
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert "rpc" in data
    assert "ipfs" in data
    assert data["ipfs"]["connected"] is True, f"Kubo IPFS chưa chạy: {data['ipfs']}"

@pytest.mark.asyncio
async def test_ipfs_roundtrip_cidv1():
    sample = b'{"hello": "IS355 AMM DEX", "version": 1}'
    cid = await ipfs_client.add_bytes(sample, filename="test.json")
    assert cid.startswith("baf"), f"CID không phải CIDv1: {cid}"

    downloaded = await ipfs_client.get_bytes(cid)
    assert downloaded == sample
