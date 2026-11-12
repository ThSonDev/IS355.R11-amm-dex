# Kế hoạch - Cả nhóm

> Thuộc [`PLAN.md`](../PLAN.md) (quy định chung, mốc, Definition of Done, bảng tổng hợp). Thiết kế: [`ARCHITECTURE.md`](../ARCHITECTURE.md).

## Tuần 0 - Khởi động (T5 12/11 → CN 15/11)

**Mục tiêu tuần:** cả 4 người chạy được môi trường; hiểu toán AMM; interface chốt (M0); rủi ro lớn (Sepolia ETH, OZ v5, RainbowKit offline, CID Kubo/Pinata) đã được kiểm chứng.

<a id="w0-all"></a>
### Cả nhóm - Tuần 0

#### ALL-01 · Cài môi trường · [#4](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/4)

- **Hạn:** T6 13/11 · **Ước lượng:** 0.5 ngày · **Phụ thuộc:** DV-01 (repo đã dựng)
- **Mục tiêu:** ai cũng chạy được mọi phần của dự án, không chỉ phần của mình.
- **Input:** [`docs/SETUP.md`](../SETUP.md) do Sơn viết (DV-01). Máy Windows dùng WSL2.
- **Hướng dẫn logic:**
  1. Cài Git, Foundry (`foundryup`), Node.js LTS theo `.nvmrc`, Python theo `.python-version`, Kubo (IPFS).
  2. Tạo profile trình duyệt riêng và cài MetaMask. Import 6 tài khoản Anvil mặc định, đặt tên theo vai trò ở ARCHITECTURE 4.8.
  3. Thêm mạng Anvil vào MetaMask: RPC `http://127.0.0.1:8545`, chainId 31337.
  4. Clone repo, chạy `forge build`, `npm install`, cài thư viện Python.
- **Output:** ảnh chụp kết quả `scripts/doctor.sh` gửi vào nhóm.
- **Done khi:** `scripts/doctor.sh` báo đủ; MetaMask thấy 6 ví Anvil. Bước nào trong SETUP sai thì sửa luôn bằng PR.
- **Bẫy:** Foundry cần thêm `~/.foundry/bin` vào PATH và mở lại terminal; đừng dùng ví cá nhân.

#### ALL-02 · Bài tập toán AMM · [#5](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/5)

- **Hạn:** T7 14/11 · **Ước lượng:** 0.5 ngày · **Phụ thuộc:** không
- **Mục tiêu:** ai cũng tự tính được swap, phí, LP; đây là câu hỏi phản biện chắc chắn gặp.
- **Input:** ARCHITECTURE mục 3, Uniswap V2 whitepaper.
- **Hướng dẫn logic:** tính tay (hoặc Excel) với pool 1.000 A / 1.000 B, phí 0.3%:
  1. Swap 100 A thì nhận bao nhiêu B? Giá spot trước và sau? Price impact?
  2. `k` trước và sau swap thay đổi thế nào, vì sao tăng?
  3. Người nạp đầu nạp 1.000/1.000 nhận bao nhiêu LP? Người thứ hai nạp 100 A thì cần bao nhiêu B và nhận bao nhiêu LP?
  4. Nếu đặt slippage 0.5% cho câu 1 thì `amountOutMin` là bao nhiêu?
- **Output:** đáp án gửi nhóm. Đáp án câu 1 xấp xỉ 90,66 B.
- **Done khi:** cả 4 người ra cùng kết quả và giải thích được câu 2.

#### ALL-03 · Đọc và phản hồi ARCHITECTURE + PLAN · [#6](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/6)

- **Hạn:** T7 14/11 · **Ước lượng:** 0.5 ngày · **Phụ thuộc:** không
- **Mục tiêu:** phát hiện chỗ khó hiểu hoặc sai trước khi chốt interface.
- **Hướng dẫn logic:** đọc kỹ phần mình phụ trách và phần mình phải dùng (ví dụ Nhàn đọc kỹ mục 4.3, 7). Ghi câu hỏi thành comment trong issue "ARCHITECTURE review".
- **Done khi:** mỗi người có ít nhất 1 nhận xét hoặc xác nhận "đã hiểu" cho từng mục liên quan.

#### PM-01 · Họp kickoff · [#1](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/1)

- **Hạn:** T6 13/11 · Chủ trì: Sơn
- Nội dung:
  - mục tiêu, lịch (A2), vai trò (A3), quy định (A5-A7);
  - chọn kênh chat và giờ họp tuần;
  - mỗi người nói thời gian bận trong 4 tuần tới, để Lead tính lại tải.

---

## Tuần 1 - Lõi chạy local (T2 16/11 → CN 22/11)

**Mục tiêu tuần (M1):** trên Anvil, người dùng add liquidity → swap → remove **qua giao diện**. Token, Staking và Registry có test pass. Backend mã hóa được và đã kiểm chứng giải mã trên trình duyệt.

<a id="w1-all"></a>
### Cả nhóm - Tuần 1

- **Họp tuần CN 22/11:**
  - Sơn và Nhàn demo swap trên giao diện;
  - Minh chạy `forge test`;
  - Quyền demo mã hóa Python và giải mã trên trình duyệt.
- **Đánh giá M1:** nếu trễ thì Lead phân lại task tuần 2 ngay trong họp.
- **Bắt đầu thu minh chứng (A8)** từ tuần này.

---

## Tuần 2 - Đủ tính năng (T2 23/11 → CN 29/11)

**Mục tiêu tuần (M2):** mọi chức năng chạy end-to-end trên local; lên Sepolia (M2a, T6 27/11); feature freeze CN 29/11 kèm tổng duyệt lần 1.

<a id="w2-all"></a>
### Cả nhóm - Tuần 2

- **Viết nháp chương báo cáo** của mình (chỉ gạch đầu dòng + ảnh minh chứng đã thu), hạn **CN 29/11**.
- **QA-21 · Tổng duyệt lần 1** · [#35](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/35) (CN 29/11, cả nhóm, chủ trì Sơn):
  - chạy toàn bộ kịch bản ở ARCHITECTURE từ `dev.sh --fresh`;
  - ghi mọi lỗi thành issue có nhãn `bug`, phân mức chặn / không chặn;
  - **mọi lỗi mức chặn phải sửa xong trước T3 01/12** (cổng điểm cộng).

---

## Tuần 3 - Hoàn thiện (T2 30/11 → CN 06/12)

**Mục tiêu tuần (M3):** không còn lỗi chặn; demo ổn định qua 3 lần tổng duyệt; video có phụ đề; báo cáo và slide đạt checklist TC5; minh chứng Sepolia đầy đủ.

<a id="w3-all"></a>
### Cả nhóm - Tuần 3

#### QA-30 · Bug bash chéo · [#48](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/48)

- **Hạn:** T2 30/11 · **Ước lượng:** 0.5 ngày mỗi người
- Mỗi người test phần của người khác như một người dùng "vụng về": nhập số âm, số rất lớn, đổi ví giữa chừng, đổi mạng, từ chối ký, mạng chậm.
  - Sơn test Governance + Receipts.
  - Minh test Swap + Pool.
  - Nhàn test backend qua giao diện (biên lai, memo, RBAC).
  - Quyền test luồng trên Sepolia.
- Ghi issue `bug` có các bước tái hiện.

#### Lịch tổng duyệt

| Lần | Ngày | Điều kiện |
|---|---|---|
| 2 | T4 02/12 | Theo `demo-script.md`, bấm giờ, có người đóng vai giảng viên hỏi phản biện |
| 3 | T7 05/12 | **Tắt Wi-Fi**, chạy từ `dev.sh` trên đúng laptop sẽ dùng khi demo, đúng thứ tự như thật |

#### DOC-30 · Viết chương báo cáo · [#56](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/56)

- **Hạn:** nộp bản đầy đủ cho Quyền vào **T5 03/12**.
- Mỗi người hoàn thiện chương của mình theo DOC-01.
- Mỗi hình và bảng phải có caption; mỗi viết tắt mới phải ghi vào bảng viết tắt; mỗi nguồn tham khảo phải ghi vào danh mục.

#### PM-30 · Chuẩn bị câu hỏi phản biện · [#62](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/62)

- **Hạn:** T6 04/12.
- Mỗi người viết 5 câu hỏi khó về phần mình kèm câu trả lời, ví dụ:
  - "vì sao `amountOut` không bao giờ vượt reserve?";
  - "admin có rút được tiền không?";
  - "vì sao mã hóa dữ liệu đã công khai?";
  - "impermanent loss là gì?".
- Gộp vào `docs/qa-prep.md`; cả nhóm đọc hết, không chỉ phần mình.
