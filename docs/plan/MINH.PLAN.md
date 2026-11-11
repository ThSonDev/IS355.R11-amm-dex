# Kế hoạch - Minh

> Thuộc [`PLAN.md`](../PLAN.md) (quy định chung, mốc, Definition of Done, bảng tổng hợp). Thiết kế: [`ARCHITECTURE.md`](../ARCHITECTURE.md).

## Tuần 0 - Khởi động (T5 12/11 → CN 15/11)

**Mục tiêu tuần:** cả 4 người chạy được môi trường; hiểu toán AMM; interface chốt (M0); rủi ro lớn (Sepolia ETH, OZ v5, RainbowKit offline, CID Kubo/Pinata) đã được kiểm chứng.

<a id="w0-minh"></a>
### Minh - Tuần 0

#### SC-02 · Kiểm chứng OpenZeppelin v5

- **Hạn:** CN 15/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** DV-01
- **Mục tiêu:** xử lý các mục chưa chắc ở ARCHITECTURE mục 14 trước khi chốt interface.
- **Input:** ARCHITECTURE 4.4-4.6 và mục 14.
- **Hướng dẫn logic:**
  1. Vào OZ Wizard, tab Governor: chọn Votes (ERC20Votes), Timelock (TimelockController), quorum 4%, clock theo block number. Lấy code về `contracts/src/DEXGovernor.sol`.
     - Sửa để `votingDelay`, `votingPeriod` và `proposalThreshold` được **truyền qua constructor**, vì Anvil và Sepolia cần giá trị khác nhau.
     - Ghi lại kiểu dữ liệu của từng tham số.
  2. Tab ERC20 trên Wizard: chọn Permit + Votes. Lấy khung `DEXToken` và ghi lại các override bắt buộc.
  3. Compile thử. Ghi các khác biệt so với ARCHITECTURE vào issue và báo Sơn để cập nhật interface.
  4. Viết một forge test nhỏ xác nhận biên `votingDelay`: tạo proposal ở block N rồi vote ở block N+1 thì revert, vote ở N+2 thì được.
- **Output:** `DEXGovernor.sol`, `DEXToken.sol` (khung), một test biên, ghi chú khác biệt.
- **Done khi:** compile pass; test biên pass; mục 14 dòng 1-3 được tick.
- **Bẫy:** Wizard có thể chọn clock theo timestamp; phải chọn **block number** để khớp ARCHITECTURE.

#### ALL-04 (Minh) · Học Foundry cơ bản

- **Hạn:** CN 15/11 · **Ước lượng:** 1 ngày
- Làm theo Foundry Book phần "Writing tests": test một ERC20 đơn giản với `vm.prank`, `vm.expectRevert`, `vm.warp`.
- Đây là kỹ năng cần cho mọi task tuần 1.

---

## Tuần 1 - Lõi chạy local (T2 16/11 → CN 22/11)

**Mục tiêu tuần (M1):** trên Anvil, người dùng add liquidity → swap → remove **qua giao diện**. Token, Staking và Registry có test pass. Backend mã hóa được và đã kiểm chứng giải mã trên trình duyệt.

<a id="w1-minh"></a>
### Minh - Tuần 1

#### SC-13 · `TestToken` (TokenA, TokenB)

- **Hạn:** T3 17/11 · **Ước lượng:** 0.5 ngày · **Phụ thuộc:** SC-01
- **Mục tiêu:** hai token ERC-20 để giao dịch (README TC4); task khởi động cho Solidity.
- **Hướng dẫn logic:**
  1. Kế thừa ERC20 và Ownable (truyền `initialOwner`).
  2. `mint` chỉ cho owner.
  3. `faucet`: lưu thời điểm nhận gần nhất của từng địa chỉ. Nếu chưa đủ 24h thì revert `FaucetCooldown` (kèm thời điểm được nhận lại). Ngược lại mint 1.000 token, emit `FaucetClaimed`.
- **Done khi:** có test mint bởi owner/người lạ, faucet lần 1 thành công, lần 2 revert, sau `vm.warp` 24h thì nhận lại được, sau `renounceOwnership` thì không ai mint được.

#### SC-14 · `DEXToken`

- **Hạn:** T4 18/11 · **Ước lượng:** 0.5 ngày · **Phụ thuộc:** SC-02
- **Mục tiêu:** token thưởng và token biểu quyết.
- **Hướng dẫn logic:** hoàn thiện khung từ SC-02:
  - mint 1.000.000 DEX cho địa chỉ nhận trong constructor;
  - không có hàm mint nào khác.
- **Done khi:** có test:
  - tổng cung đúng;
  - `getVotes` = 0 trước khi delegate, bằng số dư sau khi tự delegate;
  - chuyển token thì quyền vote đi theo;
  - `getPastVotes` ở block cũ không đổi.

#### SC-15 · `StakingRewards`

- **Hạn:** T7 21/11 · **Ước lượng:** 2 ngày · **Phụ thuộc:** SC-14 (cần LP token để test; dùng một ERC20 giả làm LP)
- **Mục tiêu:** Yield Farming: stake LP, nhận DEX (README TC4).
- **Input:** ARCHITECTURE 4.5; tìm đọc giải thích mô hình "Synthetix StakingRewards".
- **Hướng dẫn logic** (hiểu kỹ trước khi code, đây là phần hay bị hỏi):
  1. Ý tưởng chính: thay vì cộng thưởng cho từng người mỗi giây, contract lưu **"thưởng tích lũy trên mỗi LP"** (`rewardPerTokenStored`), tăng theo thời gian với tốc độ `rewardRate / tổng stake`.
  2. Với mỗi người, contract nhớ giá trị "thưởng trên mỗi LP" tại lần cuối cập nhật. Thưởng của họ = số stake × (giá trị hiện tại − giá trị đã nhớ) + thưởng đã cộng dồn.
  3. **Trước mọi thao tác** (stake, withdraw, getReward), cập nhật giá trị toàn cục và giá trị của người gọi. Thường làm bằng một modifier "updateReward".
  4. Thời điểm tính thưởng không vượt quá `periodFinish`.
  5. **`notifyRewardAmount`:** chỉ `REWARD_DISTRIBUTOR_ROLE`; chỉ khi kỳ trước đã hết; rate = reward / duration; kiểm tra contract đang giữ đủ DEX; đặt `periodFinish` = bây giờ + duration.
  6. `stake`, `withdraw`, `getReward` là `public`. `exit` gọi phiên bản nội bộ để tránh lỗi gọi `external` từ bên trong.
  7. **Không** có hàm cho admin rút token.
- **Done khi:** có test:
  - một người stake suốt kỳ nhận ≈ toàn bộ thưởng;
  - hai người stake bằng nhau nhận bằng nhau;
  - người vào giữa kỳ nhận theo thời gian tham gia;
  - withdraw và exit trả đủ LP;
  - notify khi chưa hết kỳ → revert; notify khi thiếu số dư → revert;
  - tổng thưởng đã trả ≤ tổng đã nạp.
- **Bẫy:**
  - chia cho tổng stake = 0;
  - quên nhân 1e18 khi tính "thưởng trên mỗi LP" nên mất độ chính xác.

#### SC-16 · `DEXRegistry`

- **Hạn:** CN 22/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** SC-01
- **Mục tiêu:** RBAC cho tài nguyên IPFS (rubric TC3).
- **Input:** ARCHITECTURE 4.7, 5.
- **Hướng dẫn logic:**
  1. AccessControl với 3 role và admin truyền qua constructor.
  2. **Token list:** lưu CID hiện tại và số phiên bản. `setTokenList` yêu cầu đúng role và CID không rỗng; tăng version; emit event.
  3. **Biên lai:**
     - mapping từ txHash sang Receipt;
     - mapping từ trader sang danh sách txHash.
     - `attachReceipt`: yêu cầu đúng role, CID không rỗng, chưa tồn tại (`ReceiptExists`); lưu timestamp là thời điểm block; emit event.
- **Done khi:** có test cho mọi lỗi, đúng/sai role, cấp rồi thu hồi role thì quyền mất ngay, `receiptsOf` trả đúng danh sách.

---

## Tuần 2 - Đủ tính năng (T2 23/11 → CN 29/11)

**Mục tiêu tuần (M2):** mọi chức năng chạy end-to-end trên local; lên Sepolia (M2a, T6 27/11); feature freeze CN 29/11 kèm tổng duyệt lần 1.

<a id="w2-minh"></a>
### Minh - Tuần 2

#### SC-21 · Governor + Timelock + test governance end-to-end

- **Hạn:** T3 24/11 · **Ước lượng:** 1.5 ngày · **Phụ thuộc:** SC-02, SC-14, SC-10
- **Mục tiêu:** đề xuất đổi phí qua bỏ phiếu (README TC3, Governance Proposals).
- **Hướng dẫn logic:**
  1. Hoàn thiện `DEXGovernor` từ SC-02; dựng Timelock trong test theo đúng cách cấu hình của SC-20.
  2. **Test luồng đầy đủ:**
     - 3 ví có DEX, đã delegate;
     - propose đổi phí 30 → 50 bps với description chứa `ipfs://<CID giả>`;
     - `vm.roll` qua votingDelay;
     - 2 ví For, 1 ví Against;
     - `vm.roll` hết votingPeriod;
     - queue; `vm.warp` qua minDelay; execute;
     - kiểm tra `feeBps` = 50 và event `FeeUpdated`.
  3. **Test thất bại:**
     - thiếu quorum → Defeated;
     - đề xuất phí 150 bps → execute revert (vượt trần);
     - người có votes < threshold → propose revert;
     - gọi `setFee` trực tiếp không qua Timelock → revert.
- **Done khi:** mọi test pass; ghi lại các bước để đưa vào chương báo cáo.

#### SC-22 · Rà bảo mật và NatSpec

- **Hạn:** T5 26/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** SC-10..SC-21
- **Hướng dẫn logic:**
  1. Đi qua checklist ARCHITECTURE mục 8 cho **từng contract**; ghi kết quả từng dòng (đạt / không đạt / không áp dụng) vào `docs/security-checklist.md`.
  2. Kiểm tra không còn hàm nào cho phép admin rút token của người dùng.
  3. Thêm NatSpec (`@notice`, `@param`, `@return`) cho mọi hàm public, bằng tiếng Anh.
  4. Đọc chéo code của Sơn (Pair/Router) với câu hỏi: "nếu tôi là kẻ tấn công thì gọi hàm nào theo thứ tự nào?"
- **Output:** `docs/security-checklist.md`, PR thêm NatSpec, comment review vào PR của Sơn.
- **Done khi:** Lead duyệt checklist.

#### FE-21 · Trang Governance

- **Hạn:** CN 29/11 · **Ước lượng:** 2.5 ngày · **Phụ thuộc:** FE-10, SC-21, BE-21 (endpoint upload PDF)
- **Mục tiêu:** README TC3: tài liệu đề xuất thay đổi phí lưu IPFS; người dùng thao tác bỏ phiếu.
- **Input:** wireframe FE-02, component của Nhàn, ARCHITECTURE 4.6.
- **Hướng dẫn logic:**
  1. **Thẻ "Quyền biểu quyết":** số dư DEX, số votes hiện tại, đã delegate cho ai. Nút "Kích hoạt quyền biểu quyết" (tự delegate) nếu chưa có.
  2. **Form tạo đề xuất** (chỉ hiện khi votes ≥ threshold):
     - nhập tiêu đề, phí mới (bps; hiển thị dạng %; cảnh báo nếu > 1%), chọn file PDF;
     - Bước 1: ký message → POST lên backend → nhận CID → hiển thị link gateway để xem lại;
     - Bước 2: dựng description theo đúng định dạng ARCHITECTURE, gọi `propose`.
  3. **Danh sách đề xuất:**
     - đọc event `ProposalCreated` từ `deployBlock`;
     - mỗi đề xuất hiển thị tiêu đề, link PDF (trích CID từ description), phí đề xuất, trạng thái (`state`), số phiếu For/Against/Abstain, block bắt đầu và kết thúc vote.
  4. **Nút theo trạng thái:**
     - Active → 3 nút vote;
     - Succeeded → "Queue + Execute": queue, rồi khi Timelock hết thời gian chờ thì execute, có đếm ngược;
     - Executed → hiện phí mới.
     - Dùng **description gốc lấy từ event** để tính hash khi queue/execute.
  5. **Chỉ trên Anvil:** hiện gợi ý "dùng `chain.sh skip` để tua thời gian" khi đang chờ.
- **Done khi:** thực hiện trọn một vòng trên giao diện với 3 ví, phí trên Pool Dashboard đổi theo.
- **Bẫy:**
  - vote ngay sau khi propose sẽ revert, vì vote mở từ block propose + 2;
  - tự dựng lại description khi queue sẽ sai hash.

---

## Tuần 3 - Hoàn thiện (T2 30/11 → CN 06/12)

**Mục tiêu tuần (M3):** không còn lỗi chặn; demo ổn định qua 3 lần tổng duyệt; video có phụ đề; báo cáo và slide đạt checklist TC5; minh chứng Sepolia đầy đủ.

<a id="w3-minh"></a>
### Minh - Tuần 3

#### QA-32 · Sửa bug contract và giao diện Governance

- **Hạn:** T3 01/12 · Theo issue từ QA-21/QA-30.

#### DV-31 · CI GitHub Actions (điểm cộng, nếu cổng mở)

- **Hạn:** T5 03/12 · **Ước lượng:** 0.5 ngày
- **Hướng dẫn logic:** workflow chạy trên mỗi PR, gồm cài Foundry → `forge build` → `forge test`, và cài Python → pytest phần không cần Kubo. Badge trạng thái trên README.
- **Done khi:** PR mới có dấu tick xanh.

#### DOC-32 · Chương 5.2 và phần kiểm thử contract trong Ch6

- **Hạn:** T5 03/12
- **Nội dung:**
  - Token (TKA, TKB, DEX, LP);
  - Staking: giải thích "thưởng trên mỗi LP" bằng ví dụ số;
  - Governance: sơ đồ luồng propose → execute;
  - RBAC: bảng role.
- Kết quả test, coverage, gas report (có caption).
