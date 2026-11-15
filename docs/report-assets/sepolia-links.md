# Sepolia: ví, faucet, link minh chứng

> Chỉ ghi địa chỉ công khai và link Etherscan. **Không bao giờ ghi private key.**

## Ví dev

| Vai trò | Địa chỉ | Ghi chú |
|---|---|---|
| Deployer | [`0x2896f8c185129cE5A21406e4C61EF0c40D6BF45f`](https://sepolia.etherscan.io/address/0x2896f8c185129cE5A21406e4C61EF0c40D6BF45f) | 1,055 ETH (kiểm tra 15/11) |
| Backend | (chưa tạo) | Chuyển ~0,1 ETH từ Deployer khi có |

## Faucet đã dùng

| Ngày | Faucet | Nhận | Điều kiện |
|---|---|---|---|
| 13/11 | Google Cloud Web3 Faucet | 0,05 ETH | Đăng nhập Google, 1 lần/ngày |
| 13/11 | Sepolia PoW Faucet (đào trong trình duyệt) | 1,005 ETH | Không cần tài khoản; để tab chạy |

Ước lượng: chưa đo (`forge test --gas-report` khi có contract). Số dư hiện tại vượt xa mức ước tính ban đầu 0,2 ETH × 2.

## Contract đã deploy (DV-21)

(điền sau khi deploy + verify)
