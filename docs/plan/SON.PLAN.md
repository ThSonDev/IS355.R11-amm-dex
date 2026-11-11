# Kế hoạch - Sơn (Lead)

> Thuộc [`PLAN.md`](../PLAN.md) (quy định chung, mốc, Definition of Done, bảng tổng hợp). Thiết kế: [`ARCHITECTURE.md`](../ARCHITECTURE.md).

## Tuần 0 - Khởi động (T5 12/11 → CN 15/11)

**Mục tiêu tuần:** cả 4 người chạy được môi trường; hiểu toán AMM; interface chốt (M0); rủi ro lớn (Sepolia ETH, OZ v5, RainbowKit offline, CID Kubo/Pinata) đã được kiểm chứng.

<a id="w0-son"></a>
### Sơn (Lead) - Tuần 0

#### DV-01 · Dựng repo và quy trình

- **Hạn:** T5 12/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** không
- **Mục tiêu:** khung repo chuẩn để 4 người làm song song ngay.
- **Input:** ARCHITECTURE mục 10.
- **Hướng dẫn logic:**
  1. Tạo cấu trúc thư mục `contracts/` (khởi tạo Foundry), `frontend/`, `backend/`, `deployments/`, `scripts/`, `docs/report-assets/`.
  2. Tạo `.gitignore` (out, cache, node_modules, .env, .anvil, __pycache__), `.env.example`, `.nvmrc`, `.python-version`.
  3. Cài OpenZeppelin Contracts v5 vào Foundry; ghim phiên bản solc trong `foundry.toml`.
  4. Bật bảo vệ nhánh `main` (cần PR + 1 approve).
  5. Tạo template PR (checklist DoD) và template issue (các trường của task ở A4).
  6. Tạo các nhãn: `sc`, `fe`, `be`, `dv`, `qa`, `doc`, `interface-change`, `blocked`, `bug`, `bonus`.
  7. Tạo GitHub Project (cột: Backlog, Todo, In Progress, In Review, Done) và milestone M0, M1, M2, M3.
  8. Viết phần "Cài đặt và chạy" trong README.
- **Output:** repo có khung; README có hướng dẫn cài.
- **Done khi:** một thành viên khác clone và chạy `forge build` thành công.

#### SC-01 · Viết interface contract và chốt

- **Hạn:** CN 15/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** DV-01, phản hồi từ ALL-03
- **Mục tiêu:** có ABI thật để frontend và backend làm song song khi contract chưa xong.
- **Input:** ARCHITECTURE mục 4.
- **Hướng dẫn logic:**
  1. Với mỗi contract ở mục 4, viết một file interface Solidity (`IAMMPair`, `IAMMRouter`, `IStakingRewards`, `IDEXRegistry`, `ITestToken`), gồm đủ hàm, event và custom error đúng như tài liệu.
  2. Governor và DEXToken dùng ABI chuẩn OZ nên không cần interface riêng, nhưng ghi danh sách hàm mà frontend sẽ gọi.
  3. `forge build` để sinh ABI.
  4. Họp nhanh 15 phút với Nhàn và Quyền để xác nhận họ có đủ hàm và event cần dùng.
  5. Tag `interface-v1`.
- **Output:** `contracts/src/interfaces/*.sol`, tag `interface-v1`.
- **Done khi:** compile được; Nhàn và Quyền xác nhận đủ.
- **Bẫy:** đặt tên tham số và event khớp tuyệt đối với ARCHITECTURE; frontend decode event theo tên.

#### DV-02 · Định dạng `deployments/<chain>.json` và script export

- **Hạn:** CN 15/11 · **Ước lượng:** 0.5 ngày · **Phụ thuộc:** SC-01
- **Mục tiêu:** một nguồn địa chỉ và ABI duy nhất cho frontend và backend.
- **Hướng dẫn logic:**
  1. Chốt cấu trúc file: `chainId`, `deployBlock`, `commit` (git hash), `contracts` (tên → `{address, abi}`), `accounts` (vai trò → địa chỉ, chỉ với Anvil).
  2. Viết script đọc ABI trong `out/` và địa chỉ từ kết quả `forge script` (file broadcast), rồi ghi ra file trên.
  3. Tạm thời làm một file mẫu (`deployments/example.json`) với địa chỉ giả để frontend và backend code trước.
- **Output:** `scripts/export-deployments.*`, `deployments/example.json`, mô tả định dạng trong README.
- **Done khi:** Nhàn và Quyền load được file mẫu trong code của họ.

#### DV-03 · Xin Sepolia ETH

- **Hạn:** CN 15/11 (bắt đầu ngay T5) · **Ước lượng:** 0.5 ngày rải rác · **Phụ thuộc:** không
- **Mục tiêu:** tránh rủi ro R3.
- **Hướng dẫn logic:**
  1. Tạo 2 ví dev: Deployer và Backend.
  2. Thử nhiều faucet Sepolia; ghi lại faucet nào hoạt động và điều kiện của nó.
  3. Nhờ cả nhóm cùng xin rồi chuyển về ví Deployer.
  4. Ước tính cần bao nhiêu: deploy khoảng 8 contract + seed + vài chục giao dịch demo. Đo thực tế trên Anvil bằng `--gas-report`.
- **Output:** ghi chú trong `docs/report-assets/sepolia-links.md` (địa chỉ ví, số dư, faucet).
- **Done khi:** ví Deployer có đủ ETH cho ước tính ×2.

#### PM-02 · Hỏi giảng viên

- **Hạn:** T6 13/11
- Các câu hỏi:
  - số trang báo cáo và số slide yêu cầu, có template không;
  - thời lượng thuyết trình;
  - Sepolia có được chấp nhận làm testnet không;
  - demo trên chain local kèm minh chứng Sepolia có được không.
- Ghi câu trả lời vào ARCHITECTURE mục 13 và cập nhật DOC-01.

---

## Tuần 1 - Lõi chạy local (T2 16/11 → CN 22/11)

**Mục tiêu tuần (M1):** trên Anvil, người dùng add liquidity → swap → remove **qua giao diện**. Token, Staking và Registry có test pass. Backend mã hóa được và đã kiểm chứng giải mã trên trình duyệt.

<a id="w1-son"></a>
### Sơn (Lead) - Tuần 1

#### SC-10 · `AMMPair` (Core)

- **Hạn:** T4 18/11 · **Ước lượng:** 2 ngày · **Phụ thuộc:** SC-01
- **Mục tiêu:** lõi AMM: giữ reserve, mint/burn LP, swap theo x·y=k có phí, thu phí cho LP.
- **Input:** ARCHITECTURE mục 3 và 4.2.
- **Hướng dẫn logic:**
  1. **Constructor:** lưu `token0` và `token1`, đặt phí 30 bps, cấp `DEFAULT_ADMIN_ROLE` và `FEE_SETTER_ROLE` cho `admin`. Contract kế thừa ERC20 (tên "AMM LP", ký hiệu "AMM-LP").
  2. **Hàm nội bộ cập nhật reserve:** ghi reserve mới bằng số dư thực tế, emit `Sync`. Mọi hàm ghi đều kết thúc bằng hàm này.
  3. **`mint(to)`:**
     - Đọc số dư thực của hai token. Lượng vừa nạp = số dư − reserve.
     - Nếu tổng cung LP = 0: liquidity = căn bậc hai (a·b) − 1000, và mint 1000 LP cho `0xdead`.
     - Ngược lại: liquidity = min(a·S/rA, b·S/rB).
     - Yêu cầu liquidity > 0. Mint cho `to`, cập nhật reserve, emit `Mint`.
  4. **`burn(to)`:**
     - Lượng LP cần đốt là số LP **đang nằm trong chính Pair** (Router đã chuyển vào).
     - Mỗi token trả về = LP · số dư / S. Yêu cầu cả hai > 0.
     - Đốt LP, chuyển token cho `to`, cập nhật reserve, emit `Burn`.
  5. **`swap(out0, out1, to)`:**
     - Kiểm tra đúng một chiều ra > 0; `out0 < r0` và `out1 < r1`; `to` không phải địa chỉ token.
     - Chuyển token ra trước (kiểu "lạc quan" như V2), sau đó đọc số dư.
     - Suy ra lượng vào theo công thức ở mục 3; yêu cầu có token vào.
     - Kiểm tra k có phí.
     - Cộng `feeAccrued` = lượng vào × phí / 10000.
     - Cập nhật reserve, emit `Swap`.
  6. **`setFee`:** chỉ `FEE_SETTER_ROLE`; yêu cầu ≤ `MAX_FEE_BPS`; emit `FeeUpdated` với giá trị cũ và mới.
  7. Gắn `nonReentrant` cho mint/burn/swap. Dùng `SafeERC20` khi chuyển token.
- **Output:** `src/AMMPair.sol`, `test/AMMPair.t.sol`.
- **Done khi:** có test cho:
  - lần mint đầu (1000 LP tới `0xdead`) và mint lần hai đúng tỷ lệ;
  - burn trả đúng phần;
  - swap đúng công thức;
  - swap đòi quá nhiều → revert k;
  - swap trên pool rỗng → `InsufficientLiquidity`;
  - `out >= reserve` → `InsufficientLiquidity`;
  - `feeAccrued` đúng;
  - `setFee` bởi người lạ → revert; `setFee` > 1% → revert;
  - gửi token thẳng vào Pair không phá hỏng logic.
- **Bẫy:**
  - nhầm thứ tự token0/token1;
  - quên rằng lượng vào phải tính sau khi đã trừ phần chuyển ra;
  - phép nhân trong k-check phải nhân 10000 hai lần ở vế phải.

#### SC-11 · `AMMRouter`

- **Hạn:** T6 20/11 · **Ước lượng:** 1.5 ngày · **Phụ thuộc:** SC-10
- **Mục tiêu:** cửa giao tiếp an toàn cho người dùng: tỷ lệ tối ưu, slippage, deadline, event cho backend.
- **Input:** ARCHITECTURE 4.3.
- **Hướng dẫn logic:**
  1. Constructor lưu địa chỉ Pair, đọc `token0`/`token1` để biết thứ tự. Quy ước: tokenA = token0, tokenB = token1 (ghi rõ trong NatSpec).
  2. **Kiểm tra deadline** đầu mọi hàm ghi.
  3. **`addLiquidity`:**
     - Pool rỗng: dùng đúng lượng mong muốn.
     - Ngược lại: tính B tối ưu = quote(A mong muốn). Nếu ≤ B mong muốn thì kiểm tra ≥ BMin và dùng; nếu không thì tính A tối ưu = quote(B mong muốn), kiểm tra ≥ AMin.
     - Chuyển hai token từ người dùng **thẳng vào Pair**, rồi gọi `pair.mint(to)`.
  4. **`removeLiquidity`:** chuyển LP từ người dùng vào Pair, gọi `pair.burn(to)`, đổi kết quả theo thứ tự token, kiểm tra ≥ AMin/BMin.
  5. **`getAmountOut`:** kiểm tra token hợp lệ, lấy reserve theo chiều, đọc `feeBps` **trực tiếp từ Pair**, áp công thức mục 3; reserve = 0 thì `InsufficientLiquidity`.
  6. **`swapTokens`:**
     - Ghi lại reserve trước swap.
     - Tính `amountOut`; yêu cầu ≥ `amountOutMin` (`InsufficientOutput`).
     - Chuyển tokenIn từ người dùng vào Pair, gọi `pair.swap` với chiều ra đúng.
     - Emit `SwapExecuted` (trader = `msg.sender`, phí = amountIn × feeBps / 10000, reserve trước swap).
- **Output:** `src/AMMRouter.sol`, `test/AMMRouter.t.sol`.
- **Done khi:** có test cho:
  - từng lỗi ở bảng ràng buộc 4.3;
  - add lần hai với tỷ lệ lệch chỉ lấy đúng tỷ lệ;
  - luồng đầy đủ add → swap → remove;
  - LP rút sau nhiều swap nhận giá trị mỗi LP lớn hơn (theo `sqrt(k)/S`);
  - event `SwapExecuted` có đúng các trường.

#### SC-12 · Fuzz và invariant test

- **Hạn:** CN 22/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** SC-11
- **Mục tiêu:** chứng minh tính đúng bằng kiểm thử tự động; đây là điểm nhấn trong báo cáo.
- **Hướng dẫn logic:**
  1. **Fuzz:**
     - Với amountIn và reserve ngẫu nhiên trong giới hạn hợp lý, `getAmountOut` khớp công thức tham chiếu viết lại trong test, và luôn nhỏ hơn reserveOut.
     - Add rồi remove ngay (giá không đổi) không mất quá phần làm tròn.
  2. **Invariant:** viết một "handler" gọi ngẫu nhiên add, swap, remove và chuyển token thẳng vào Pair. Sau mỗi chuỗi lệnh kiểm tra:
     - `k` không giảm qua các swap;
     - `reserve <= balanceOf`;
     - tổng cung LP ≥ 1000 khi đã có thanh khoản.
  3. Xuất `forge coverage` và `--gas-report` làm minh chứng.
- **Output:** `test/AMM.fuzz.t.sol`, `test/AMM.invariant.t.sol`, ảnh minh chứng.
- **Done khi:** chạy với số lần fuzz mặc định mà pass; có ảnh chụp kết quả.

#### DV-10 · Deploy, Seed v1 và `dev.sh` v1

- **Hạn:** CN 22/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** SC-11, SC-13, DV-02
- **Mục tiêu:** một lệnh dựng môi trường local có pool sẵn để Nhàn làm giao diện.
- **Hướng dẫn logic:**
  1. `Deploy.s.sol` (bản v1): deploy TokenA, TokenB, Pair, Router.
     - Tạm thời admin của Pair là ví #0; tuần 2 đổi sang Timelock.
  2. `Seed.s.sol` (bản v1): mint TKA/TKB cho các ví #1-#3, ví LP nạp 10.000/10.000.
  3. Chạy script export ra `deployments/anvil.json`.
  4. `scripts/dev.sh` v1: khởi động Anvil (`--block-time 2`, `--state`), deploy + seed nếu chưa có, export.
- **Output:** script và `deployments/anvil.json`.
- **Done khi:** Nhàn chạy `dev.sh` trên máy mình và thấy pool có reserve trên giao diện.

#### PM-10 · Review và gỡ chặn

Ưu tiên review PR của Minh (contract) và của Nhàn (FE-10, FE-11) trong ngày.

---

## Tuần 2 - Đủ tính năng (T2 23/11 → CN 29/11)

**Mục tiêu tuần (M2):** mọi chức năng chạy end-to-end trên local; lên Sepolia (M2a, T6 27/11); feature freeze CN 29/11 kèm tổng duyệt lần 1.

<a id="w2-son"></a>
### Sơn (Lead) - Tuần 2

#### SC-20 · Deploy/Seed đầy đủ với governance và bảng quyền

- **Hạn:** T3 24/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** SC-14, SC-15, SC-16, SC-21 (khung Governor đã có từ SC-02)
- **Mục tiêu:** cấu hình quyền đúng ARCHITECTURE 4.6 và 4.8; đây là cơ sở cho luận điểm non-custodial.
- **Hướng dẫn logic:**
  1. **Thứ tự deploy:**
     1. TokenA, TokenB, DEXToken;
     2. Timelock (admin tạm = deployer);
     3. Governor (tham số theo chain);
     4. Pair (admin = Timelock);
     5. Router;
     6. Staking (admin = Timelock, distributor = deployer);
     7. Registry (admin = ví #0).
  2. **Cấu hình Timelock:** `PROPOSER` và `CANCELLER` cho Governor, `EXECUTOR` cho địa chỉ 0, rồi deployer renounce `DEFAULT_ADMIN`.
  3. **Seed:**
     - mint TKA/TKB cho ví demo; nạp thanh khoản;
     - chia DEX theo ARCHITECTURE 4.4;
     - ví LP và ví Trader tự delegate (ví Community thì **không**, để delegate trong demo);
     - chuyển 40% DEX vào Staking và gọi notify (ví dụ thời hạn 30 ngày);
     - cấp `REWARD_DISTRIBUTOR` cho Timelock, deployer renounce;
     - cấp `RECEIPT_ISSUER` cho ví #5 và `TOKEN_LIST_MANAGER` cho ví #0;
     - TestToken renounce owner.
  4. **Cuối script:** in bảng "ai giữ quyền gì" bằng cách đọc lại on-chain, rồi so với ARCHITECTURE 4.8.
  5. Viết **forge test cho chính script deploy**: sau deploy, kiểm tra từng quyền đúng bảng 4.8 và deployer không còn quyền thừa.
- **Done khi:** test quyền pass; bảng in ra khớp 4.8; ảnh chụp đưa vào báo cáo.

#### DV-20 · `dev.sh` đầy đủ và `chain.sh`

- **Hạn:** T4 25/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** SC-20, BE-12, BE-20
- **Hướng dẫn logic:**
  1. Đúng thứ tự ARCHITECTURE mục 10: Anvil → deploy/seed (nếu cần) → Kubo → publish token list → backend → frontend.
  2. Mỗi bước kiểm tra bước trước đã sẵn sàng: chờ RPC trả block, chờ Kubo trả version.
  3. Cờ `--fresh`: xóa state Anvil và deployments local; in nhắc reset MetaMask.
  4. Thoát an toàn: Ctrl+C dừng mọi tiến trình con.
  5. `chain.sh`: lệnh `mine <N>` và `skip <giây>` (tăng thời gian + mine 1 block) cho governance.
- **Done khi:** Minh hoặc Quyền chạy được `dev.sh --fresh` trên máy họ từ đầu đến cuối mà không cần hỏi.

#### DV-21 · Deploy Sepolia và verify (M2a)

- **Hạn:** T6 27/11 · **Ước lượng:** 1 ngày · **Phụ thuộc:** SC-20, DV-03
- **Hướng dẫn logic:**
  1. Chạy cùng script deploy với tham số Sepolia (ARCHITECTURE 4.6).
  2. Verify mọi contract trên Etherscan (cần API key Etherscan trong `.env`).
  3. Export `deployments/sepolia.json` (kèm `deployBlock`).
  4. Seed tối thiểu trên Sepolia: nạp thanh khoản, nạp thưởng staking, cấp role.
  5. Ghi mọi địa chỉ và link vào `sepolia-links.md`.
  6. Chạy thử 1 swap trên Sepolia qua giao diện.
- **Done khi:** mọi contract hiện "Verified" trên Etherscan; giao diện kết nối Sepolia swap được.

#### QA-20 · Tích hợp và phân loại bug

- **Hạn:** CN 29/11 · **Ước lượng:** rải rác cả tuần
- Ghép PR của mọi người; mỗi tối chạy `dev.sh --fresh` một lần trên `main`; ghi lỗi thành issue.
- Bắt đầu **ghi nháp kịch bản demo** cùng Nhàn: thứ tự bước, ví nào làm gì.

---

## Tuần 3 - Hoàn thiện (T2 30/11 → CN 06/12)

**Mục tiêu tuần (M3):** không còn lỗi chặn; demo ổn định qua 3 lần tổng duyệt; video có phụ đề; báo cáo và slide đạt checklist TC5; minh chứng Sepolia đầy đủ.

<a id="w3-son"></a>
### Sơn (Lead) - Tuần 3

#### QA-31 · Minh chứng Sepolia đầy đủ

- **Hạn:** T4 02/12 · **Ước lượng:** 1 ngày · **Phụ thuộc:** DV-21, mọi tính năng
- **Hướng dẫn logic:**
  1. Trên Sepolia chạy luồng: add → swap nhỏ → swap lớn (biên lai) → xem phiếu → stake → claim → remove.
  2. Chạy trước một vòng governance đầy đủ (mất khoảng 8-10 phút).
  3. Quay màn hình toàn bộ (video phụ cho phần testnet).
  4. Chụp link Etherscan của từng giao dịch, ghi vào `sepolia-links.md`.
- **Done khi:** đủ link và video cho tiêu chí "triển khai và kiểm thử trên testnet".

#### PM-31 · Cổng điểm cộng (T3 01/12)

- **Điều kiện mở cổng:** không còn bug mức chặn; tổng duyệt lần 1 đã qua.
- **Đề xuất thứ tự** (chọn tối đa 2, mỗi cái ≤ 1 ngày):
  1. CI GitHub Actions chạy `forge test` + pytest (Minh).
  2. Biểu đồ giá từ event `Sync`/`SwapExecuted` (Nhàn, nếu dư sức).
  3. Factory + stablecoin giả (Sơn). **Chỉ làm khi mọi thứ khác xanh**, vì đụng interface.
- Ghi quyết định vào issue.

#### DOC-31 · Chương báo cáo của Lead + duyệt cuối

- **Hạn:** T5 03/12 (chương của mình), T7 05/12 (duyệt toàn bộ).
- Viết Ch1-4, 5.1, phần chung của Ch6.
- **Nhấn mạnh** Non-custodial và Counterparty Risk (README mục 4), kèm bảng quyền 4.8 làm bằng chứng.
- Duyệt cuối: đối chiếu bảng ARCHITECTURE mục 11; mỗi dòng phải chỉ được hình, bảng hoặc mục trong báo cáo làm bằng chứng.

#### DV-30 · Đóng gói nộp

- **Hạn:** CN 06/12.
- README hướng dẫn chạy từ đầu, có danh sách phiên bản công cụ.
- Tag `v1.0`; xuất PDF báo cáo; slide; video; file link Sepolia.
- Kiểm tra repo không có secret (tìm theo chuỗi khóa và `.env`).
