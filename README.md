# IS355.R11 - Công nghệ Blockchain

* **Giảng viên hướng dẫn:** ThS. Hà Lê Hoài Trung
* **Đề tài:** Bài tập 12: XÂY DỰNG SÀN GIAO DỊCH PHI TẬP TRUNG (DEX) DỰA TRÊN AMM

## Danh sách thành viên
| STT | MSSV | Họ và tên | GitHub | Vai trò / Nhiệm vụ |
| :---: | :---: | :--- | :--- | :---: |
| 1 | 23521360 | Phạm Nguyễn Thanh Sơn | [@ThSonDev](https://github.com/ThSonDev) | Lead |
| 2 | 23520959 | Trần Tuấn Minh | [@TunMinhh](https://github.com/TunMinhh) | *** |
| 3 | 23521323 | Lê Gia Quyền | [@LeGiaQuyen](https://github.com/LeGiaQuyen) | *** |
| 4 | 22521009 | Võ Thanh Nhàn | [@FelikVo2202](https://github.com/FelikVo2202) | *** |

## Nội dung đề tài

### Bài tập 12: Xây dựng sàn giao dịch phi tập trung (DEX) dựa trên AMM

### 1. Mô tả bài toán

Sinh viên xây dựng một mô hình sàn giao dịch phi tập trung (DEX) đơn giản dựa trên cơ chế **Automated Market Maker (AMM)**, tương tự như Uniswap. Hệ thống cho phép người dùng:

- **Liquidity Providers (LP):** Cung cấp thanh khoản vào pool để nhận phí giao dịch.
- **Traders:** Hoán đổi (Swap) giữa hai loại token khác nhau dựa trên công thức toán học **x × y = k**.

### 2. Yêu cầu thực hiện chi tiết theo Rubric

#### Tiêu chí 1: Xây dựng và triển khai hợp đồng thông minh (10 điểm)

Phát triển logic lõi của sàn giao dịch bằng Solidity.

**3 nghiệp vụ chính:**

- `addLiquidity()`: Cho phép người dùng gửi một cặp token vào pool theo tỷ lệ giá hiện tại.
- `swapTokens()`: Thực hiện hoán đổi từ Token A sang Token B dựa trên công thức sản phẩm không đổi.
- `removeLiquidity()`: Cho phép người cung cấp thanh khoản rút lại token kèm theo phần phí thu được.

**2 ràng buộc logic:**

- **Kiểm tra số dư:** Đảm bảo pool luôn có đủ thanh khoản trước khi thực hiện lệnh swap.
- **Trượt giá (Slippage):** Thiết lập ràng buộc để giao dịch bị hủy nếu giá trị nhận được thấp hơn mức người dùng kỳ vọng, nhằm bảo vệ người dùng khỏi biến động giá mạnh.

#### Tiêu chí 2: Tương tác qua Web3.py / Frontend (10 điểm)

Xây dựng giao diện người dùng để tương tác với pool thanh khoản.

**Giao diện:**

- **Swap Interface:** Ô nhập số lượng token muốn đổi và hiển thị tỷ giá ước tính theo thời gian thực.
- **Pool Dashboard:** Hiển thị tổng giá trị bị khóa (TVL) trong sàn và phần thưởng dự kiến cho các LP.

**Mã hóa / Bảo mật:**

- Tích hợp ví MetaMask.
- Đảm bảo dữ liệu về giá được cập nhật chính xác từ Smart Contract thông qua Web3.py/Web3.js trước khi người dùng nhấn nút xác nhận.

#### Tiêu chí 3: Tích hợp IPFS (10 điểm)

Lưu trữ thông tin bổ trợ và cấu hình của sàn giao dịch.

**3 loại dữ liệu lưu trữ:**

- **Token List:** File JSON chứa danh sách các token được hỗ trợ, bao gồm tên, ký hiệu, địa chỉ contract và mã hash logo.
- **Trade Receipts:** Bản tóm tắt lịch sử các giao dịch lớn (PDF/JSON) được lưu trữ để phục vụ đối soát.
- **Governance Proposals:** Các tài liệu đề xuất thay đổi phí giao dịch của cộng đồng.

**Thao tác:**

- **Upload:** Khi người dùng thực hiện giao dịch lớn, hệ thống tạo biên lai số và đẩy lên IPFS.
- **Retrieve:** Người dùng có thể xem lại "phiếu giao dịch" thông qua liên kết IPFS được gắn trên ID giao dịch.

#### Tiêu chí 4: Tạo và triển khai Token ERC-20 / NFT (10 điểm)

Hiện thực hóa việc giao dịch các tài sản thực tế.

**ERC-20 (DEX Tokens):**

- Sinh viên cần tạo ít nhất **2 Token ERC-20** (ví dụ: `TokenA` và `TokenB`) để thực hiện giao dịch trên sàn.

**LP Token (Liquidity Provider Token):**

- Khi người dùng nạp thanh khoản, hệ thống tự động mint một loại token đại diện cho phần sở hữu của họ trong pool.
- Khi người dùng rút thanh khoản, LP Token tương ứng sẽ bị burn.

**2 nghiệp vụ sử dụng Token:**

1. **Staking:** Sử dụng LP Token để nhận thêm phần thưởng (Yield Farming).
2. **Fee Collection:** Tự động trích một tỷ lệ nhỏ token từ mỗi giao dịch swap để trả cho người nắm giữ LP Token.

### 3. Quy trình thực hiện gợi ý cho sinh viên (Workflow)

1. **Giai đoạn 1 – Toán học:** Tìm hiểu công thức **x × y = k** và hiểu cách giá tự động thay đổi khi số lượng token trong pool biến động.
2. **Giai đoạn 2 – Smart Contract:** Viết hợp đồng lõi (Core) và hợp đồng định tuyến (Router) để điều phối các lệnh swap.
3. **Giai đoạn 3 – Frontend:** Xây dựng giao diện đơn giản, chú trọng vào việc tính toán **Price Impact** (Tác động giá) để hiển thị cho người dùng.
4. **Giai đoạn 4 – Demo:** Nạp thanh khoản cho cặp `TokenA/TokenB` → thực hiện swap → kiểm tra cách phí giao dịch được cộng vào pool.

### 4. Giá trị cốt lõi từ sách

**Chương 10** nhấn mạnh rằng DEX giải quyết vấn đề **Counterparty Risk** (Rủi ro đối tác) vì người dùng luôn giữ khóa bí mật của mình trong suốt quá trình giao dịch.

Sinh viên nên nêu bật được tính chất **Non-custodial** (Không lưu ký) của DEX trong báo cáo.

## Tài liệu tham khảo
* Slides bài giảng Công nghệ blockchain, Khoa HTTT, Đại học CNTT
* Kok, A.S., 2024. Hands-On Blockchain for Python Developers: Empowering Python developers in the world of blockchain and smart contracts. Packt Publishing Ltd
* Damsker, A., 2024. Understanding DeFi: The Roles, Tools, Risks, and Rewards of Decentralized Finance. " O'Reilly Media, Inc
* Garg, R., 2023. Blockchain for real world applications. John Wiley & Sons.
* Ashurst, S. and Tempesta, S., 2021. Blockchain applied: practical technology and use cases of enterprise blockchain for the real world. Productivity Press.
* Narayanan, A., Bonneau, J., Felten, E., Miller, A. and Goldfeder, S., 2016. Bitcoin and cryptocurrency technologies: a comprehensive introduction. Princeton University Press.
