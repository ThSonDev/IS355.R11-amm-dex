from fastapi import APIRouter
from backend.app.chain.client import check_rpc_status
from backend.app.ipfs.client import ipfs_client

router = APIRouter()

@router.get("/health")
async def health_check():
    rpc_info = check_rpc_status()
    try:
        ipfs_ver = await ipfs_client.get_version()
        ipfs_info = {"connected": True, "version": ipfs_ver}
    except Exception as exc:
        ipfs_info = {"connected": False, "error": str(exc)}

    status = "ok" if (rpc_info["connected"] and ipfs_info["connected"]) else "degraded"
    return {
        "status": status,
        "rpc": rpc_info,
        "ipfs": ipfs_info,
    }
