# IS355 AMM DEX — Backend Service

## 1. Kiến trúc bảo mật & Tách bạch khóa (Key Separation)
- **Khóa kiểm toán (`RSA-3072` + `OAEP-SHA256`):** `keys/auditor_public.pem` bọc khóa phiên AES-256-GCM; `keys/auditor_private.pem` giữ ngoại tuyến (quyền `0600`, hỗ trợ PKCS#8 `--passphrase`). `AUDITOR_PUBKEY_FINGERPRINT` chống tráo khóa công khai.
- **Khóa chủ máy chủ (`SERVER_MASTER_KEY` — 256-bit CSPRNG):** Mã hóa khóa phiên cục bộ (Envelope Encryption).
- **Khóa ký biên lai (`RECEIPT_SIGNER_PRIVATE_KEY` — ECDSA `secp256k1`):** Ký xác thực tính toàn vẹn và chống chối bỏ cho biên lai off-chain.

## 2. Cách sinh khóa
- Chế độ Dev/CI: `python3 backend/scripts/gen_keys.py`
- Chế độ Production: `python3 backend/scripts/gen_keys.py --passphrase "<mat-khau-manh>"`
- Lưu ý: Không commit thư mục `keys/`, file `*.pem` hoặc `.env` lên Git.
