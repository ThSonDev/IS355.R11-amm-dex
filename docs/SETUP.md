# Cài đặt và chạy môi trường

> Mục tiêu: người mới clone repo, làm theo từ trên xuống trong khoảng 30 phút là chạy được `scripts/dev.sh` và thấy pool trên giao diện, không cần hỏi ai.
> Lệnh nào ở đây cũng phải đã được chạy thử. Gặp bước sai hoặc thiếu: sửa file này trong PR, đừng chỉ báo miệng.

Mục có đánh dấu *(chờ X)* sẽ được người làm task X bổ sung khi phần đó có code.

## 0. Hệ điều hành

- Chỉ hỗ trợ **Linux** (Ubuntu 22.04/24.04 hoặc tương đương).
- Máy Windows: dùng **WSL2 + Ubuntu**, clone repo *bên trong* WSL (`~/...`, không để ở `/mnt/c/...` vì chậm và lỗi quyền file). Trình duyệt và MetaMask chạy bên Windows vẫn gọi được `127.0.0.1:8545` của WSL.
- macOS: không hỗ trợ chính thức; thường chạy được với cùng lệnh nhưng tự xử lý khác biệt.

## 1. Bức tranh khi chạy local

| Tiến trình | Vai trò | Cổng |
|---|---|---|
| Anvil | Blockchain local (chainId 31337, block 2 giây) | 8545 |
| Kubo (IPFS) | Lưu logo, token list, biên lai mã hóa | 5001 (API), 8080 (gateway) |
| Backend (FastAPI) | Nghe event, tạo biên lai, API cho frontend | 8000 |
| Frontend (Vite) | Giao diện web | 5173 |

`scripts/dev.sh` khởi động tất cả theo đúng thứ tự ở ARCHITECTURE mục 10.

## 2. Cài công cụ

Phiên bản lấy theo file ghim trong repo, không tự chọn bản khác.

| Công cụ | Ghim ở | Kiểm tra |
|---|---|---|
| Git | - | `git --version` |
| Foundry (forge, anvil, cast) | `contracts/foundry.toml` (solc) | `forge --version` |
| Node.js | `.nvmrc` | `node -v` |
| Python | `.python-version` | `python3 --version` |
| Kubo | ghi ở bảng này | `ipfs version` |

*(chờ DV-01)* Lệnh cài từng công cụ.

Chạy kiểm tra tổng: `scripts/doctor.sh` báo công cụ nào thiếu, sai phiên bản, cổng nào đang bị chiếm.

## 3. Clone và cài thư viện

*(chờ DV-01)* Clone, `forge build`.
*(chờ FE-01)* Cài thư viện frontend.
*(chờ BE-01)* Môi trường ảo Python, cài thư viện backend, `ipfs init`.

## 4. Cấu hình `.env`

- Chép `.env.example` thành `.env`. `.env` đã nằm trong `.gitignore`, **không bao giờ commit**.
- Private key của Anvil là key công khai, ai cũng biết, chỉ dùng cho local.
- Key ví Sepolia chỉ Lead giữ. Không dán key vào chat nhóm hay công cụ AI.

*(chờ DV-01, BE-01)* Giải thích từng biến.

## 5. MetaMask

1. Tạo một **profile trình duyệt riêng** cho dự án; cài MetaMask trong đó. Không dùng ví cá nhân.
2. Thêm mạng: tên `Anvil`, RPC `http://127.0.0.1:8545`, chainId `31337`, ký hiệu `ETH`.
3. Import 6 tài khoản Anvil mặc định (`anvil` in ra khi khởi động), đặt tên theo vai trò:

| # | Tên trong MetaMask |
|---|---|
| 0 | Admin |
| 1 | LP |
| 2 | Trader |
| 3 | Community |
| 4 | Auditor |
| 5 | Backend |

4. Sau mỗi lần `dev.sh --fresh`: MetaMask → Settings → Advanced → **Clear activity tab data** cho từng tài khoản, nếu không sẽ lỗi nonce.

## 6. Chạy hằng ngày

*(chờ DV-10, DV-20)*

- `scripts/dev.sh`: chạy tiếp từ state cũ.
- `scripts/dev.sh --fresh`: xóa state, deploy và seed lại.
- `scripts/chain.sh`: mine block, tua thời gian (dùng khi test governance, staking).
- Dấu hiệu chạy đúng: mở `http://localhost:5173`, kết nối ví Trader, thấy reserve pool 10.000 / 10.000.

## 7. Theo vai trò

| Người | Thường chạy |
|---|---|
| Contract (Sơn, Minh) | `forge test`, `forge test --gas-report` |
| Frontend (Nhàn) | *(chờ FE-01)* |
| Backend (Quyền) | *(chờ BE-01)* |

## 8. Sepolia (chỉ Lead)

*(chờ DV-21)* Deploy, verify, ghi `deployments/sepolia.json`. Địa chỉ ví và faucet: `docs/report-assets/sepolia-links.md`.

## 9. Lỗi hay gặp

| Triệu chứng | Cách xử lý |
|---|---|
| `forge: command not found` sau khi cài | Mở terminal mới hoặc `source ~/.bashrc` (Foundry thêm `~/.foundry/bin` vào PATH) |
| MetaMask báo nonce sai, giao dịch treo | Clear activity tab data (mục 5) |
| `address already in use` | `scripts/doctor.sh` chỉ ra cổng; tắt tiến trình cũ |
| Kubo báo chưa có repo | `ipfs init` một lần |
