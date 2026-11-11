# Kế hoạch - Nhàn

> Thuộc [`PLAN.md`](../PLAN.md) (quy định chung, mốc, Definition of Done, bảng tổng hợp). Thiết kế: [`ARCHITECTURE.md`](../ARCHITECTURE.md).

## Tuần 0 - Khởi động (T5 12/11 → CN 15/11)

**Mục tiêu tuần:** cả 4 người chạy được môi trường; hiểu toán AMM; interface chốt (M0); rủi ro lớn (Sepolia ETH, OZ v5, RainbowKit offline, CID Kubo/Pinata) đã được kiểm chứng.

<a id="w0-nhan"></a>
### Nhàn - Tuần 0

#### FE-01 · Khung frontend và kết nối ví · [#12](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/12)

- **Hạn:** CN 15/11 · **Ước lượng:** 1.5 ngày · **Phụ thuộc:** DV-01
- **Mục tiêu:** khung chạy được, kết nối MetaMask với Anvil; kiểm chứng rủi ro R6.
- **Input:** ARCHITECTURE mục 7 (phần Ví).
- **Hướng dẫn logic:**
  1. **Quyết định TypeScript hay JavaScript cùng Lead** (ARCHITECTURE mục 13). Khuyến nghị TypeScript vì wagmi suy ra kiểu từ ABI và bắt lỗi gọi sai hàm ngay khi gõ. Ghi quyết định vào ARCHITECTURE.
  2. Tạo dự án Vite + React. Cài wagmi, viem, RainbowKit, TanStack Query (wagmi cần).
  3. Cấu hình 2 chain: Anvil (31337) và Sepolia. Connector **chỉ dùng injected/MetaMask**, không WalletConnect.
  4. Tạo layout: header (logo, menu 4 trang, nút kết nối ví, cảnh báo sai mạng) và 4 route trống: Swap, Pool, Governance, History.
  5. **Thử tắt Wi-Fi:** chạy lại frontend và kết nối ví với Anvil. Ghi kết quả vào ARCHITECTURE mục 14. Nếu RainbowKit lỗi khi offline thì báo Lead (Kế hoạch B ở R6).
  6. Font và icon để local, không lấy từ CDN.
- **Output:** `frontend/` chạy bằng `npm run dev`; ảnh chụp kết nối ví.
- **Done khi:** kết nối và ngắt ví được; đổi sang mạng khác thì thấy cảnh báo; chạy được khi offline.

#### FE-02 · Wireframe 4 trang · [#13](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/13)

- **Hạn:** CN 15/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** không
- **Mục tiêu:** thống nhất giao diện trước khi code; ai làm trang Governance hay Receipts cũng theo cùng một kiểu.
- **Input:** ARCHITECTURE mục 7, bảng 4 trang.
- **Hướng dẫn logic:**
  1. Vẽ (Figma hoặc giấy rồi chụp) 4 trang. Mỗi trang ghi rõ: hiển thị dữ liệu gì, đọc từ hàm hay event nào, nút nào gửi giao dịch nào.
  2. Định nghĩa bộ component chung: card, nút chính/phụ, ô nhập số token (có nút MAX, hiển thị số dư), toast trạng thái giao dịch (chờ ký → đang xử lý → thành công/thất bại kèm link tx), bảng.
  3. Chọn bảng màu có độ tương phản đủ. Ảnh chụp UI sẽ đưa vào slide (TC5).
  4. Liệt kê mọi trạng thái của trang Swap: chưa kết nối, sai mạng, chưa nhập, thiếu số dư, cần approve, đang chờ, lỗi slippage, thành công.
- **Output:** `docs/design/wireframes/*.png` + `docs/design/README.md` (component, màu, trạng thái).
- **Done khi:** họp CN 15/11 thông qua.

---

## Tuần 1 - Lõi chạy local (T2 16/11 → CN 22/11)

**Mục tiêu tuần (M1):** trên Anvil, người dùng add liquidity → swap → remove **qua giao diện**. Token, Staking và Registry có test pass. Backend mã hóa được và đã kiểm chứng giải mã trên trình duyệt.

<a id="w1-nhan"></a>
### Nhàn - Tuần 1

#### FE-10 · Lớp cấu hình contract và hooks dùng chung · [#24](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/24)

- **Hạn:** T3 17/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** DV-02, FE-01
- **Mục tiêu:** cả nhóm frontend (Nhàn, Minh, Quyền) dùng chung một cách đọc/ghi contract.
- **Hướng dẫn logic:**
  1. Đọc `deployments/<chainId>.json` theo chain đang kết nối; tạm thời đọc `example.json`.
  2. Tạo các hàm/hook dùng chung:
     - lấy địa chỉ và ABI theo tên contract;
     - đọc số dư và allowance token;
     - **"gửi giao dịch an toàn"**: simulate → gửi → chờ receipt → toast trạng thái;
     - **dịch custom error** của contract sang câu tiếng Việt (ví dụ `InsufficientOutput` → "Giá đã thay đổi vượt mức trượt giá cho phép").
  3. Hàm định dạng số token (18 decimals ↔ chuỗi hiển thị); không dùng số thực JavaScript cho số tiền.
- **Output:** thư mục `frontend/src/lib/` (hoặc tương đương) + README ngắn hướng dẫn dùng cho Minh và Quyền.
- **Done khi:** một trang thử đọc được số dư TKA của ví đang kết nối trên Anvil.
- **Bẫy:** số token là `bigint`; đổi qua `number` sẽ mất chính xác.

#### FE-11 · Trang Swap v1 · [#25](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/25)

- **Hạn:** CN 22/11 · **Ước lượng:** 2.5 ngày · **Phụ thuộc:** FE-10, SC-11 (trước khi SC-11 merge thì dùng công thức mô phỏng ở client)
- **Mục tiêu:** README TC2: nhập số lượng, tỷ giá realtime, price impact, bảo vệ slippage.
- **Input:** ARCHITECTURE mục 3 và 7; wireframe FE-02.
- **Hướng dẫn logic:**
  1. Hai ô token (vào/ra), nút đảo chiều, hiển thị số dư, nút MAX.
  2. **Báo giá theo block:** mỗi khi có block mới hoặc người dùng đổi số lượng (debounce khoảng 300 ms), gọi `getAmountOut`.
  3. Hiển thị:
     - tỷ giá (1 TKA = x TKB);
     - **price impact** (công thức mục 3; tô vàng khi > 1%, đỏ khi > 5%);
     - phí (số token);
     - **minimum received** = báo giá × (1 − slippage).
  4. Cài đặt slippage: 0.1%, 0.5% (mặc định), 1%, hoặc nhập tay; cảnh báo khi > 5%.
  5. **Nút hành động theo trạng thái:** Kết nối ví → Sai mạng → Nhập số lượng → Không đủ số dư → Approve TKA (approve **đúng số cần**) → Swap.
  6. **Khi bấm Swap** (4 bước ở mục 7):
     - đọc lại báo giá; nếu lệch quá slippage so với số đang hiển thị thì hiện hộp xác nhận lại;
     - **deadline = timestamp của block mới nhất + 20 phút**;
     - simulate rồi gửi.
  7. Sau khi thành công: toast có link tx, cập nhật số dư.
- **Output:** trang Swap; ảnh chụp từng trạng thái cho báo cáo.
- **Done khi:**
  - swap thật trên Anvil thành công cả hai chiều;
  - dùng ví khác swap chen vào giữa lúc chờ thì giao dịch bị chặn hoặc revert đúng thông báo slippage;
  - mọi trạng thái ở bước 5 đều hiển thị đúng.
- **Bẫy:**
  - dùng `Date.now()` cho deadline;
  - quên đọc lại allowance sau khi approve.

#### FE-12 · Header: ví, mạng, faucet · [#26](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/26)

- **Hạn:** T4 18/11 · **Ước lượng:** 0.5 ngày · **Phụ thuộc:** FE-01, SC-13
- **Hướng dẫn logic:**
  - Nút Faucet gọi `faucet()` của TKA hoặc TKB.
  - Nếu revert `FaucetCooldown` thì hiển thị "Thử lại sau <thời gian>".
  - Hiển thị chain hiện tại.
- **Done khi:** nhận faucet thành công; nhận lần hai thấy thông báo chờ.

---

## Tuần 2 - Đủ tính năng (T2 23/11 → CN 29/11)

**Mục tiêu tuần (M2):** mọi chức năng chạy end-to-end trên local; lên Sepolia (M2a, T6 27/11); feature freeze CN 29/11 kèm tổng duyệt lần 1.

<a id="w2-nhan"></a>
### Nhàn - Tuần 2

#### FE-20 · Trang Pool (thanh khoản + dashboard + farm)

Trang lớn, chia 3 PR.

**FE-20a · Thêm/rút thanh khoản** · [#39](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/39)

- **Hạn:** T3 24/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** FE-10, SC-11
- **Hướng dẫn logic:**
  1. **Thêm:**
     - nhập một token thì tự điền token kia theo tỷ lệ reserve (dùng `quote`);
     - hiển thị số LP dự kiến nhận và phần sở hữu pool sau khi nạp;
     - approve từng token nếu cần (đúng số cần);
     - `addLiquidity` với min = số dự kiến × (1 − slippage), deadline theo block.
  2. **Rút:**
     - thanh trượt 25/50/75/100% số LP;
     - hiển thị số TKA/TKB dự kiến nhận;
     - approve LP cho Router;
     - `removeLiquidity`.
  3. Hiển thị số LP của ví, phần sở hữu (%), giá trị quy ra TKA/TKB.
- **Done khi:** thêm và rút thành công, số liệu dự kiến khớp số thực nhận (sai lệch trong mức làm tròn).

**FE-20b · Pool Dashboard** · [#40](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/40)

- **Hạn:** T5 26/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** FE-20a, SC-10 (`feeAccrued`)
- **Mục tiêu:** README TC2 (TVL + phần thưởng dự kiến cho LP) và README Workflow (thấy phí cộng vào pool).
- **Hướng dẫn logic:** đọc mỗi block rồi hiển thị:
  1. reserve hai token, giá hai chiều, `k`, `sqrt(k)/S` (giá trị mỗi LP);
  2. **TVL** theo TKB (công thức mục 7, ghi rõ đơn vị);
  3. phí đang áp dụng (`feeBps`);
  4. **phí tích lũy** quy TKB, **Fee APR ước tính** (có chú thích "ước tính");
  5. **phí của bạn** (ước tính, cách tính ở mục 7);
  6. **ô "Trước/Sau swap gần nhất"**: k, `sqrt(k)/S`, `feeAccrued` của lần swap trước và sau. Đây là bằng chứng phí vào pool khi demo.
- **Done khi:** sau một swap, ô Trước/Sau cho thấy `k` và `sqrt(k)/S` tăng, `feeAccrued` tăng đúng bằng phí.

**FE-20c · Farm** · [#41](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/41)

- **Hạn:** T7 28/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** FE-20a, SC-15
- **Hướng dẫn logic:**
  1. Hiển thị LP đang stake, tổng stake, `earned` (giữa hai block thì nội suy theo `rewardRate` để số chạy mượt), DEX/ngày ước tính, thời gian còn lại của kỳ thưởng.
  2. Các nút:
     - Approve LP + Stake;
     - Unstake (một phần hoặc tất cả);
     - Claim;
     - Exit.
- **Done khi:** stake, chờ, claim thì số DEX nhận khớp `earned`.

#### FE-22 · Ô memo trên trang Swap · [#42](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/42)

- **Hạn:** T7 28/11 · **Ước lượng:** 0.5 ngày · **Phụ thuộc:** FE-11, BE-20
- **Hướng dẫn logic:**
  - Ô "Ghi chú đối soát" (tùy chọn, tối đa ~200 ký tự), kèm chú thích "chỉ bạn và kiểm toán viên đọc được, chỉ áp dụng cho giao dịch lớn".
  - Ngay khi có txHash, ký message (txHash + memo) và POST lên backend.
  - Nếu ước tính đây là giao dịch lớn (amountIn ≥ 2% reserve), hiển thị nhãn "Giao dịch lớn - sẽ có biên lai".
- **Done khi:** swap lớn có memo thì biên lai sau khi giải mã chứa đúng memo.

#### QA-22 · Nháp `demo-script.md` · [#43](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/43)

- **Hạn:** CN 29/11 · **Ước lượng:** 0.5 ngày · **Phụ thuộc:** QA-20
- **Hướng dẫn logic:** liệt kê từng bước demo:
  - ví nào, trang nào, bấm gì;
  - **mỗi popup MetaMask** (approve hay giao dịch chính);
  - màn hình mong đợi;
  - câu thuyết minh;
  - thời lượng.

  Thứ tự đề xuất:
  1. Test pool rỗng (kết quả forge).
  2. Kết nối ví, token list lấy từ IPFS.
  3. Add liquidity.
  4. Swap nhỏ.
  5. Swap lớn + memo.
  6. Dashboard: phí vào pool.
  7. Xem biên lai (trader).
  8. RBAC 403 → cấp quyền → 200 → thu hồi.
  9. CLI auditor.
  10. Stake + claim.
  11. Governance trọn vòng.
  12. Remove liquidity.
  13. Minh chứng Sepolia.
- **Done khi:** dùng được cho tổng duyệt lần 1.

---

## Tuần 3 - Hoàn thiện (T2 30/11 → CN 06/12)

**Mục tiêu tuần (M3):** không còn lỗi chặn; demo ổn định qua 3 lần tổng duyệt; video có phụ đề; báo cáo và slide đạt checklist TC5; minh chứng Sepolia đầy đủ.

<a id="w3-nhan"></a>
### Nhàn - Tuần 3

#### QA-33 · `demo-script.md` bản chốt · [#51](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/51)

- **Hạn:** T3 01/12 · **Phụ thuộc:** QA-22, kết quả tổng duyệt lần 1
- Hoàn thiện từ bản nháp:
  - thời lượng mỗi bước;
  - **số lần bấm MetaMask và loại giao dịch**;
  - ai thao tác, ai thuyết minh;
  - phương án khi lỗi (chuyển sang video đoạn tương ứng).

#### FE-30 · Hoàn thiện giao diện · [#54](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/54)

- **Hạn:** T4 02/12 · **Ước lượng:** 1 ngày
- Thống nhất style 4 trang (kể cả trang của Minh và Quyền).
- Kiểm tra tương phản màu, cỡ chữ đọc được khi chiếu.
- Thêm trạng thái loading và trạng thái trống; câu thông báo lỗi bằng tiếng Việt.

#### DOC-33 · Slide · [#59](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/59)

- **Hạn:** T5 03/12 · **Ước lượng:** 1 ngày · **Phụ thuộc:** DOC-01, chương của mọi người
- **Hướng dẫn logic:**
  1. Kể chuyện theo mạch: vấn đề (counterparty risk của sàn tập trung) → giải pháp (AMM, non-custodial) → kiến trúc → 4 tiêu chí (mỗi tiêu chí 1-2 slide kèm bằng chứng) → demo → kiểm thử → hạn chế và hướng phát triển.
  2. Chữ ≥ 18; mỗi hình có caption; slide cuối là tài liệu tham khảo.
- **Done khi:** thuyết trình thử vừa thời lượng giảng viên yêu cầu.

#### DOC-34 · Video demo có phụ đề · [#63](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/63)

- **Hạn:** T6 04/12 · **Ước lượng:** 1 ngày · **Phụ thuộc:** QA-33
- **Hướng dẫn logic:**
  1. Quay theo `demo-script.md` trên môi trường local sạch (`--fresh`), độ phân giải đủ đọc chữ.
  2. Thêm phụ đề cho mọi bước (file `.srt` hoặc chữ trên hình).
  3. Chia chương theo bước để khi demo trực tiếp lỗi có thể nhảy đúng đoạn.
- **Done khi:** cả nhóm xem lại và không thấy bước nào thiếu phụ đề.

#### DOC-35 · Chương 5.4 và Ch7 · [#60](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/60)

- **Hạn:** T5 03/12
- 5.4: frontend, luồng "giá chính xác trước khi xác nhận", xử lý lỗi.
- Ch7: kịch bản demo kèm ảnh chụp.
