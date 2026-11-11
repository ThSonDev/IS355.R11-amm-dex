# Kế hoạch - Quyền

> Thuộc [`PLAN.md`](../PLAN.md) (quy định chung, mốc, Definition of Done, bảng tổng hợp). Thiết kế: [`ARCHITECTURE.md`](../ARCHITECTURE.md).

## Tuần 0 - Khởi động (T5 12/11 → CN 15/11)

**Mục tiêu tuần:** cả 4 người chạy được môi trường; hiểu toán AMM; interface chốt (M0); rủi ro lớn (Sepolia ETH, OZ v5, RainbowKit offline, CID Kubo/Pinata) đã được kiểm chứng.

<a id="w0-quyen"></a>
### Quyền - Tuần 0

#### BE-01 · Khung backend và IPFS

- **Hạn:** CN 15/11 · **Ước lượng:** 1.5 ngày · **Phụ thuộc:** DV-01
- **Mục tiêu:** backend chạy được, nói chuyện được với Kubo; kiểm chứng CID giữa Kubo và Pinata.
- **Input:** ARCHITECTURE mục 6.
- **Hướng dẫn logic:**
  1. Tạo dự án FastAPI với cấu trúc thư mục: `app/` (api, listener, crypto, ipfs, chain), `scripts/`, `tests/`.
  2. Đọc cấu hình từ `.env`: RPC URL, đường dẫn deployments, URL Kubo, các khóa (để trống).
  3. `GET /health`: kiểm tra kết nối RPC (lấy block number), kết nối Kubo (lấy version), trả JSON trạng thái.
  4. Module IPFS:
     - Hàm "thêm file" gọi Kubo HTTP API `add`, dùng **CIDv1**, trả CID.
     - Hàm "tải file theo CID" qua gateway local.
  5. Thử upload cùng một file lên Kubo (CIDv1) và lên Pinata, so sánh CID. Ghi kết quả vào ARCHITECTURE mục 14. Nếu khác nhau thì tìm thiết lập của Pinata cho ra CID giống (CID version, kích thước khối); không được thì Pinata dùng "pin theo CID" thay vì upload lại.
  6. pytest: test cho `/health` và test khứ hồi upload/download (cần Kubo đang chạy).
- **Output:** `backend/` chạy bằng một lệnh; ghi chú kết quả so sánh CID.
- **Done khi:** `/health` báo RPC và IPFS OK; upload xong mở được `http://localhost:8080/ipfs/<CID>`.

#### BE-02 · Tạo cặp khóa RSA cho Auditor và quy ước khóa

- **Hạn:** CN 15/11 · **Ước lượng:** 0.5 ngày · **Phụ thuộc:** không
- **Hướng dẫn logic:**
  1. Viết script sinh cặp RSA 3072-bit. Private key ở dạng **PKCS#8 PEM** (Web Crypto chỉ nhận dạng này); public key dạng SPKI PEM.
  2. Quy ước nơi lưu:
     - public key có thể commit, vì nó công khai;
     - private key nằm ngoài repo hoặc trong thư mục đã có trong `.gitignore`.
  3. Sinh `SERVER_MASTER_KEY` (32 byte ngẫu nhiên, mã hóa base64) và ghi hướng dẫn vào `.env.example`.
- **Output:** `backend/scripts/gen_keys.py`, hướng dẫn trong README backend.
- **Done khi:** chạy script ra đúng định dạng; `.gitignore` chặn private key.

---

## Tuần 1 - Lõi chạy local (T2 16/11 → CN 22/11)

**Mục tiêu tuần (M1):** trên Anvil, người dùng add liquidity → swap → remove **qua giao diện**. Token, Staking và Registry có test pass. Backend mã hóa được và đã kiểm chứng giải mã trên trình duyệt.

<a id="w1-quyen"></a>
### Quyền - Tuần 1

#### BE-10 · Module crypto

- **Hạn:** T4 18/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** BE-02
- **Mục tiêu:** mã hóa biên lai theo ARCHITECTURE 5.1 (rubric TC2).
- **Hướng dẫn logic:**
  1. **Dựng khóa:** HKDF-SHA256 với input là master key, salt là txHash (32 byte), info là chuỗi "receipt-v1", đầu ra 32 byte. Cùng txHash luôn ra cùng khóa.
  2. **Mã hóa:** AES-256-GCM, IV ngẫu nhiên 12 byte. Đầu ra là ciphertext có tag 16 byte nối ở cuối; định dạng này Web Crypto đọc được.
  3. **Bọc khóa cho auditor:** RSA-OAEP với SHA-256 (cả hàm băm chính lẫn MGF1), bằng public key auditor.
  4. **Envelope:** đối tượng JSON theo ARCHITECTURE 5.1; dữ liệu nhị phân mã hóa base64.
  5. Các hàm ngược lại: giải mã envelope bằng K; mở `wrapAuditor` bằng private key.
- **Output:** `app/crypto/`, `tests/test_crypto.py`.
- **Done khi:** có test:
  - mã hóa rồi giải mã ra đúng bản gốc;
  - sửa 1 byte ciphertext thì giải mã báo lỗi;
  - cùng txHash ra cùng K, khác txHash ra khác K;
  - RSA bọc rồi mở ra đúng K.

#### BE-11 · Thử nghiệm interop: Python mã hóa, trình duyệt giải mã

- **Hạn:** T6 20/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** BE-10
- **Mục tiêu:** xử lý rủi ro R4 sớm.
- **Hướng dẫn logic:**
  1. Python tạo một envelope mẫu và in ra K (base64).
  2. Viết một trang HTML nhỏ hoặc test Node: nhập envelope và K → Web Crypto import khóa AES (raw) → giải mã AES-GCM → hiển thị JSON.
  3. Đường RSA: thử import private key PKCS#8 trong Web Crypto để xác nhận định dạng (chỉ để kiểm chứng; sản phẩm dùng CLI).
  4. Ghi lại các tham số cần khớp: độ dài IV, tag nằm cuối ciphertext, tên thuật toán, hàm băm OAEP.
- **Output:** `backend/tests/interop/` + ghi chú; chuyển cho Nhàn và chính Quyền dùng ở FE-23.
- **Done khi:** trình duyệt giải mã đúng envelope do Python tạo.
- **Nếu thất bại sau 1 ngày:** báo Lead, chuyển sang Kế hoạch B của R4.

#### BE-12 · Token list và logo lên IPFS

- **Hạn:** CN 22/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** BE-01; SC-16 cho bước cuối
- **Mục tiêu:** README TC3 (Token List kèm hash logo) và rubric TC3 (dữ liệu ảnh + JSON).
- **Hướng dẫn logic:**
  1. Thiết kế 3 logo đơn giản (TKA, TKB, DEX) dạng PNG hoặc SVG; nhờ Nhàn nếu cần.
  2. Script `publish_tokenlist.py`:
     - upload từng logo → lấy CID;
     - dựng JSON theo chuẩn Uniswap Token Lists: tên list, timestamp, version, danh sách token với `chainId`, `address` (đọc từ `deployments`), `symbol`, `name`, `decimals`, `logoURI = ipfs://<CID>`;
     - upload JSON → lấy CID;
     - gọi `Registry.setTokenList(cid)` bằng ví Admin.
  3. Nếu chưa có Registry (SC-16 chưa xong) thì bước cuối tạm in CID ra. Ghép bước cuối khi SC-16 merge.
  4. Kiểm tra file JSON hợp lệ theo schema của tokenlists.org (có thư viện/schema công khai).
- **Output:** script, logo trong `backend/assets/`.
- **Done khi:** mở `localhost:8080/ipfs/<CID>` thấy JSON; trong JSON, `logoURI` trỏ tới ảnh mở được.

#### DOC-01 · Template báo cáo, slide và dàn ý

- **Hạn:** CN 22/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** PM-02 (yêu cầu của giảng viên, nếu có)
- **Mục tiêu:** đạt chắc các điểm format của TC5 ngay từ đầu.
- **Hướng dẫn logic:**
  1. **Template báo cáo** (Word hoặc Google Docs, theo yêu cầu của giảng viên):
     - cỡ chữ thân bài ≥ 14;
     - heading có đánh số;
     - style caption "Hình x.y" và "Bảng x.y" tự đánh số;
     - mục lục tự động, danh mục hình, danh mục bảng;
     - **bảng chữ viết tắt**;
     - tài liệu tham khảo theo một chuẩn trích dẫn (ví dụ IEEE hoặc APA; chọn một và dùng nhất quán).
  2. **Template slide:** chữ ≥ 18 (khuyến nghị tiêu đề ≥ 28, nội dung ≥ 20); nền sáng chữ tối, tương phản cao.
  3. **Dàn ý báo cáo** và người viết từng chương:
     - Ch1 Giới thiệu (Sơn);
     - Ch2 Cơ sở lý thuyết: blockchain, DeFi, DEX và CEX, AMM, Counterparty Risk, non-custodial (Sơn);
     - Ch3 Phân tích yêu cầu (Sơn, dựa trên bảng đối chiếu);
     - Ch4 Thiết kế kiến trúc (Sơn);
     - Ch5 Hiện thực:
       - 5.1 AMM core (Sơn);
       - 5.2 Token, Staking, Governance, RBAC (Minh);
       - 5.3 Backend, IPFS, mã hóa (Quyền);
       - 5.4 Frontend (Nhàn);
     - Ch6 Kiểm thử và triển khai testnet (Sơn + Minh);
     - Ch7 Demo (Nhàn);
     - Ch8 Đánh giá, hạn chế, hướng phát triển (cả nhóm, Quyền tổng hợp);
     - Tài liệu tham khảo, Phụ lục.
  4. File `docs/report/abbreviations.md` để mọi người bổ sung viết tắt trong lúc viết.
- **Output:** template + dàn ý trong `docs/report/`.
- **Done khi:** Lead duyệt; mọi người biết mình viết chương nào.

---

## Tuần 2 - Đủ tính năng (T2 23/11 → CN 29/11)

**Mục tiêu tuần (M2):** mọi chức năng chạy end-to-end trên local; lên Sepolia (M2a, T6 27/11); feature freeze CN 29/11 kèm tổng duyệt lần 1.

<a id="w2-quyen"></a>
### Quyền - Tuần 2

#### BE-20 · Listener, biên lai, memo, hàng đợi giao dịch

- **Hạn:** T5 26/11 · **Ước lượng:** 2 ngày · **Phụ thuộc:** BE-10, SC-11, SC-16, DV-10
- **Mục tiêu:** README TC3: giao dịch lớn thì tự tạo biên lai số và đẩy lên IPFS.
- **Input:** ARCHITECTURE 5.1, 6.
- **Hướng dẫn logic:**
  1. **Con trỏ block:**
     - lưu "block cuối đã xử lý" vào file;
     - khi khởi động, nếu chainId hoặc hash của block 0 khác lần trước thì reset về `deployBlock`.
  2. **Vòng lặp mỗi 2 giây:** lấy event `SwapExecuted` từ (con trỏ + 1) đến (block mới nhất − 1). Lùi 1 block là để chờ xác nhận.
  3. **Với mỗi event:**
     1. Kiểm tra ngưỡng giao dịch lớn (công thức 5.1). Không lớn thì bỏ qua.
     2. **Idempotent:** nếu `Registry.getReceipt(txHash)` đã có thì bỏ qua (an toàn khi khởi động lại).
     3. Chờ memo tối đa 10 giây, tính từ lúc thấy event.
     4. Dựng `receipt.json` (đủ trường ở 5.1), mã hóa, đóng envelope, upload lên Kubo.
     5. Đưa `attachReceipt` vào **hàng đợi giao dịch tuần tự**.
     6. Pin sang Pinata (lỗi thì chỉ ghi log).
  4. **Hàng đợi giao dịch:** một worker duy nhất gửi lần lượt, chờ receipt rồi mới gửi tiếp; lỗi thì thử lại tối đa 3 lần rồi ghi log.
  5. **Chỉ cập nhật con trỏ** sau khi xử lý xong event.
  6. **`POST /receipts/memo`:**
     - nhận txHash, memo, chữ ký;
     - khôi phục địa chỉ người ký; lấy giao dịch theo txHash (có thể còn pending) và yêu cầu `from` = người ký;
     - lưu memo (bộ nhớ + file JSON để không mất khi khởi động lại).
- **Output:** `app/listener/`, `app/tx_queue/`, `app/api/receipts.py`, tests.
- **Done khi:**
  - swap 500 TKA tạo biên lai với CID trên Registry trong vòng khoảng 10 giây;
  - swap 50 TKA thì không tạo;
  - tắt rồi bật backend thì không tạo trùng;
  - hai swap lớn liên tiếp không lỗi nonce;
  - log rõ ràng.

#### BE-21 · Xác thực chữ ký, cấp khóa, upload proposal

- **Hạn:** T6 27/11 · **Ước lượng:** 1.5 ngày · **Phụ thuộc:** BE-20, SC-14
- **Hướng dẫn logic:**
  1. **`GET /auth/nonce`:** sinh chuỗi ngẫu nhiên, lưu kèm hạn 5 phút, trả về.
  2. **Định dạng message ký** (kiểu SIWE rút gọn, thống nhất với frontend):
     - domain;
     - chainId;
     - mục đích ("receipt-key" hoặc "proposal-upload");
     - txHash (nếu có);
     - nonce;
     - thời điểm hết hạn.
  3. **Hàm kiểm tra chung:**
     - khôi phục địa chỉ;
     - nonce tồn tại, chưa dùng, chưa hết hạn;
     - domain và chainId đúng;
     - **đánh dấu nonce đã dùng**.
  4. **`POST /receipts/key`:**
     - kiểm tra chữ ký;
     - đọc `Registry.getReceipt(txHash)`;
     - cho phép nếu người ký = trader **hoặc** `hasRole(AUDITOR_ROLE, người ký)` đọc on-chain tại thời điểm gọi;
     - đúng thì trả K (base64), sai thì **403** với thông báo rõ.
  5. **`POST /proposals/upload`:**
     - kiểm tra chữ ký;
     - yêu cầu `getVotes(người ký) ≥ proposalThreshold` (đọc threshold từ Governor);
     - chỉ nhận file có magic bytes PDF (`%PDF`) và dưới 10 MB;
     - upload, trả CID.
- **Done khi:** pytest cho:
  - chữ ký đúng/sai;
  - dùng lại nonce → từ chối; nonce hết hạn → từ chối;
  - không phải trader → 403; auditor → 200; sau khi revoke → 403;
  - file không phải PDF → 400; votes thiếu → 403.

#### FE-23 · Trang History & Receipts

- **Hạn:** CN 29/11 · **Ước lượng:** 1.5 ngày · **Phụ thuộc:** FE-10, BE-11, BE-21
- **Mục tiêu:** README TC3 (xem lại phiếu giao dịch qua link IPFS gắn trên ID giao dịch).
- **Hướng dẫn logic:**
  1. **Bảng lịch sử swap của ví đang kết nối:** đọc `SwapExecuted` lọc theo trader, từ `deployBlock`. Cột: thời gian, chiều, số lượng, giá, txHash (link explorer khi ở Sepolia), biên lai.
  2. **Cột biên lai:**
     - nếu `Registry.getReceipt(txHash)` có CID thì hiện link gateway ("Xem file gốc" - bản mã hóa) và nút **"Xem phiếu"**;
     - nếu giao dịch lớn nhưng chưa có biên lai thì hiện "Đang tạo…".
  3. **"Xem phiếu":**
     1. tải envelope qua gateway;
     2. lấy nonce → ký message → POST lấy K;
     3. giải mã bằng Web Crypto (theo BE-11);
     4. hiển thị phiếu đẹp: thông tin giao dịch, memo, CID, link Registry;
     5. nút tải về JSON đã giải mã.
  4. **Chế độ Auditor:** ô nhập txHash bất kỳ → "Xem phiếu" (backend sẽ kiểm tra role). Hiển thị lỗi 403 rõ ràng ("Ví này không có quyền AUDITOR"). Phần này dùng cho demo RBAC.
- **Done khi:**
  - trader xem được phiếu của mình;
  - ví khác bị 403;
  - được cấp `AUDITOR_ROLE` thì xem được, bị thu hồi thì lại 403.

#### BE-22 · `audit_cli`

- **Hạn:** CN 29/11 · **Ước lượng:** 0.5 ngày · **Phụ thuộc:** BE-10
- **Hướng dẫn logic:** lệnh `decrypt <txHash|CID> --key <pem>`:
  1. Nếu nhận txHash thì đọc CID từ Registry.
  2. Tải envelope qua gateway.
  3. Mở `wrapAuditor` bằng private key, giải mã, in JSON đẹp.
  4. Báo lỗi rõ khi sai khóa.
- **Done khi:** giải mã đúng khi backend đang **tắt**.

---

## Tuần 3 - Hoàn thiện (T2 30/11 → CN 06/12)

**Mục tiêu tuần (M3):** không còn lỗi chặn; demo ổn định qua 3 lần tổng duyệt; video có phụ đề; báo cáo và slide đạt checklist TC5; minh chứng Sepolia đầy đủ.

<a id="w3-quyen"></a>
### Quyền - Tuần 3

#### QA-34 · Sửa bug backend và Receipts

- **Hạn:** T3 01/12 · Theo issue từ QA-21/QA-30.

#### DOC-36 · Chương 5.3

- **Hạn:** T4 02/12
- **Nội dung:**
  - IPFS: 3 loại dữ liệu, CID, gateway;
  - RBAC: kiểm soát ghi so với kiểm soát đọc;
  - mã hóa: sơ đồ HKDF → AES-GCM → RSA-OAEP;
  - xác thực chữ ký;
  - **giới hạn** (ARCHITECTURE 5.1).

#### DOC-37 · Biên tập báo cáo tổng

- **Hạn:** T7 05/12 · **Ước lượng:** 1.5 ngày · **Phụ thuộc:** DOC-30 (mọi chương, hạn T5 03/12)
- **Hướng dẫn logic:**
  1. Ghép các chương vào template; thống nhất giọng văn và thuật ngữ (có bảng thuật ngữ Anh-Việt).
  2. Chạy checklist TC5:
     - soát chính tả (công cụ + đọc chéo 1 người);
     - mọi hình và bảng có caption, được tham chiếu trong bài;
     - bảng viết tắt đầy đủ;
     - tài liệu tham khảo đúng một chuẩn, mọi trích dẫn đều có trong danh mục;
     - cỡ chữ ≥ 14;
     - tương phản của hình chụp.
  3. Cập nhật mục lục và danh mục hình, bảng; xuất PDF.
  4. Ch8: tổng hợp đánh giá, hạn chế, hướng phát triển từ cả nhóm.
- **Done khi:** checklist TC5 tick đủ; Lead duyệt (DOC-31).
