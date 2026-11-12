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
| Kubo | **v0.43.1** (ghi ở bảng này) | `ipfs version` |

Phiên bản đang ghim: Foundry 1.9.0 (solc 0.8.30), Node 24, Python 3.12, Kubo v0.43.1.

```bash
# Git, Python 3.12 (Ubuntu 24.04 có sẵn 3.12). Không dùng pyenv global; thư viện chỉ cài trong .venv của repo
sudo apt update && sudo apt install -y git curl python3 python3-venv

# Foundry (forge, anvil, cast): cài foundryup rồi chạy; mở terminal mới sau đó
curl -L https://foundry.paradigm.xyz | bash
foundryup --install 1.9.0

# Node.js qua nvm (đọc phiên bản từ .nvmrc, chạy trong thư mục repo sau khi clone)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | bash
# mở terminal mới, rồi:
nvm install && nvm use

# Kubo (IPFS) v0.43.1
cd /tmp
curl -LO https://github.com/ipfs/kubo/releases/download/v0.43.1/kubo_v0.43.1_linux-amd64.tar.gz
tar xzf kubo_v0.43.1_linux-amd64.tar.gz
sudo bash kubo/install.sh
```

Nguồn chính thức: [Foundry](https://github.com/foundry-rs/foundry/releases), [Node.js](https://nodejs.org/en/download), [Kubo](https://github.com/ipfs/kubo/releases), [nvm](https://github.com/nvm-sh/nvm). CPU ARM thì thay `linux-amd64` bằng `linux-arm64`.

Chạy kiểm tra tổng: `scripts/doctor.sh` báo công cụ nào thiếu, sai phiên bản, cổng nào đang bị chiếm.

## 3. Clone và cài thư viện

```bash
git clone --recurse-submodules https://github.com/ThSonDev/IS355.R11-amm-dex.git
cd IS355.R11-amm-dex
cd contracts && forge build
```

Lỡ clone thiếu `--recurse-submodules` (thư mục `contracts/lib/` rỗng): chạy `git submodule update --init --recursive`. OpenZeppelin v5.7.0 và forge-std v1.17.0 là submodule đã ghim; không chạy `forge update`.
*(chờ FE-01)* Cài thư viện frontend.
Python: một môi trường ảo `.venv` ở gốc repo (đã nằm trong `.gitignore`), thư viện ghi trong `requirements.txt` ở gốc repo. Không `pip install` ra ngoài `.venv`.

```bash
python3 -m venv .venv
source .venv/bin/activate            # mỗi terminal mới đều cần chạy lại
pip install -r requirements.txt      # có từ BE-01
```

*(chờ BE-01)* `ipfs init` và chạy backend.

## 4. Cấu hình `.env`

- Chép `.env.example` thành `.env`. `.env` đã nằm trong `.gitignore`, **không bao giờ commit**.
- Private key của Anvil là key công khai, ai cũng biết, chỉ dùng cho local.
- Key ví Sepolia chỉ Lead giữ. Không dán key vào chat nhóm hay công cụ AI.

| Biến | Ý nghĩa |
|---|---|
| `RPC_URL`, `CHAIN_ID` | Anvil local: `http://127.0.0.1:8545`, `31337` |
| `IPFS_API`, `IPFS_GATEWAY` | Kubo local: `:5001` (API), `:8080` (gateway) |
| `RECEIPT_ISSUER_PRIVATE_KEY` | Backend ký biên lai; local dùng key tài khoản #5 của Anvil |
| `SERVER_MASTER_KEY` | Khóa gốc sinh khóa AES cho biên lai (64 ký tự hex); lộ khóa này là lộ mọi biên lai |
| `AUDITOR_PUBLIC_KEY_PATH` | Đường dẫn khóa công khai RSA của Auditor |
| `PINATA_JWT` | Tùy chọn, ghim bản sao dự phòng lên Pinata |
| `SEPOLIA_RPC_URL`, `DEPLOYER_PRIVATE_KEY`, `ETHERSCAN_API_KEY` | Chỉ Lead, dùng khi deploy Sepolia (mục 8) |

*(chờ BE-01)* Cách sinh khóa RSA cho Auditor.

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

### `deployments/<chain>.json`

Nguồn duy nhất của địa chỉ và ABI; frontend và backend chỉ đọc file này, không chép tay.

```json
{
  "chainId": 31337,
  "deployBlock": 1,
  "commit": "<git hash lúc deploy>",
  "contracts": { "TokenA": { "address": "0x...", "abi": [ ... ] } },
  "accounts": { "Admin": "0x...", "LP": "0x..." }
}
```

- `contracts` có đủ 9 nhãn: `TokenA`, `TokenB`, `AMMPair`, `AMMRouter`, `DEXToken`, `StakingRewards`, `DEXGovernor`, `Timelock`, `DEXRegistry`.
- `accounts` (Admin, LP, Trader, Community, Auditor, Backend) chỉ có ở Anvil; Sepolia để `{}`.
- `deployments/example.json` là file mẫu với địa chỉ giả (ABI của 5 contract riêng lấy từ interface nên chỉ có hàm khai báo trong interface, thiếu hàm ERC20/AccessControl kế thừa). Dùng để code trước khi có deploy thật.
- `deployments/anvil.json` được sinh lại trên từng máy, không commit. `sepolia.json` sẽ được commit.
- Sinh file thật (sau khi `Deploy.s.sol` chạy): `python3 scripts/export-deployments.py --chain anvil` (hoặc `sepolia`). Script đọc `deployments/<chainId>.addresses.json` (do `Deploy.s.sol` ghi), ABI trong `contracts/out/` và block deploy trong `contracts/broadcast/`.
- Kiểm tra một file: `python3 scripts/export-deployments.py --check deployments/example.json`.

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
