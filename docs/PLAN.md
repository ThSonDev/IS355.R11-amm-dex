# Kế hoạch thực hiện - AMM DEX

> Phiên bản: **v1.0** (2026-11-12). Người quản lý: Sơn (Lead).
> Tài liệu thiết kế gốc: [`ARCHITECTURE.md`](ARCHITECTURE.md). Gặp mâu thuẫn giữa hai tài liệu thì **ARCHITECTURE.md đúng**; báo Lead để sửa PLAN.
> Hạn nộp dự kiến: **T2 07/12/2026**. Kế hoạch đặt mục tiêu **xong toàn bộ vào CN 06/12**.

## Mục lục

**Phần A - Quy định chung**
[A1 Mục tiêu](#a1) · [A2 Lịch và mốc](#a2) · [A3 Vai trò](#a3) · [A4 Cách đọc task, Definition of Done](#a4) · [A5 Git và review](#a5) · [A6 Giao tiếp](#a6) · [A7 Quy tắc kỹ thuật](#a7) · [A8 Minh chứng cho báo cáo](#a8) · [A9 Rủi ro và dự phòng](#a9) · [A10 Tài liệu học](#a10)

**Phần B - Chi tiết theo tuần và thành viên**

| Tuần | Cả nhóm | Sơn (Lead) | Minh | Nhàn | Quyền |
|---|---|---|---|---|---|---|
| **Tuần 0** (12-15/11) Khởi động | [Cả nhóm](plan/TEAM.PLAN.md#w0-all) | [Sơn](plan/SON.PLAN.md#w0-son) | [Minh](plan/MINH.PLAN.md#w0-minh) | [Nhàn](plan/NHAN.PLAN.md#w0-nhan) | [Quyền](plan/QUYEN.PLAN.md#w0-quyen) |
| **Tuần 1** (16-22/11) Lõi | [Cả nhóm](plan/TEAM.PLAN.md#w1-all) | [Sơn](plan/SON.PLAN.md#w1-son) | [Minh](plan/MINH.PLAN.md#w1-minh) | [Nhàn](plan/NHAN.PLAN.md#w1-nhan) | [Quyền](plan/QUYEN.PLAN.md#w1-quyen) |
| **Tuần 2** (23-29/11) Đủ tính năng | [Cả nhóm](plan/TEAM.PLAN.md#w2-all) | [Sơn](plan/SON.PLAN.md#w2-son) | [Minh](plan/MINH.PLAN.md#w2-minh) | [Nhàn](plan/NHAN.PLAN.md#w2-nhan) | [Quyền](plan/QUYEN.PLAN.md#w2-quyen) |
| **Tuần 3** (30/11-06/12) Hoàn thiện | [Cả nhóm](plan/TEAM.PLAN.md#w3-all) | [Sơn](plan/SON.PLAN.md#w3-son) | [Minh](plan/MINH.PLAN.md#w3-minh) | [Nhàn](plan/NHAN.PLAN.md#w3-nhan) | [Quyền](plan/QUYEN.PLAN.md#w3-quyen) |

**Phần C** - [Bảng tổng hợp task](#c-summary) (dùng để tạo GitHub Issues)

---

# Phần A - Quy định chung

<a id="a1"></a>
## A1. Mục tiêu và phạm vi

**Mục tiêu duy nhất:** nộp một DEX chạy được, **đạt đủ mọi ý** trong README và rubric (bảng đối chiếu ở ARCHITECTURE mục 11). Mỗi thành viên phải **giải thích được phần mình làm** khi bị hỏi.

**Thứ tự ưu tiên khi thiếu thời gian:**

1. Ý bắt buộc của README/rubric chạy đúng trong demo.
2. Demo không lỗi (tối đa 1 lỗi giao dịch).
3. Báo cáo, slide, video đúng format tiêu chí 5.
4. Chất lượng: test, bảo mật, UI gọn đẹp.
5. Điểm cộng (ARCHITECTURE mục 12). **Chỉ làm sau cổng duyệt T3 01/12** (xem A2).

**Không làm:** những gì nằm trong mục "Không làm" của ARCHITECTURE. Ai muốn thêm tính năng ngoài phạm vi thì đề xuất với Lead; mặc định là **không**.

<a id="a2"></a>
## A2. Lịch và mốc

| Ngày | Mốc | Điều kiện đạt |
|---|---|---|
| T5 12/11 | Kickoff | Cả nhóm đọc PLAN + ARCHITECTURE, nhận task |
| **CN 15/11** | **M0 - Chốt interface** | Interface Solidity compile được, có ABI; môi trường của cả 4 người chạy được; tag `interface-v1` |
| CN 22/11 | M1 - Lõi chạy local | Trên Anvil: add liquidity → swap → remove qua giao diện; contract Token/Staking/Registry có test pass |
| T6 27/11 | M2a - Lên testnet | Toàn bộ contract deploy + verify trên Sepolia |
| **CN 29/11** | **M2 - Chốt tính năng (feature freeze)** | Mọi chức năng trong ARCHITECTURE chạy end-to-end trên local; tổng duyệt lần 1 |
| **T3 01/12** | **Cổng điểm cộng** | Lead quyết định làm điểm cộng nào, chỉ khi không còn bug mức chặn |
| T4 02/12 | Tổng duyệt lần 2 | Theo `demo-script.md`, có bấm giờ |
| T6 04/12 | Video xong | Có phụ đề |
| T7 05/12 | Báo cáo + slide xong, tổng duyệt lần 3 | Tắt Wi-Fi khi tổng duyệt |
| CN 06/12 | **M3 - Sẵn sàng nộp** | Tag `v1.0`, đóng gói nộp |
| T2 07/12 | Hạn nộp (dự kiến) | |

**Sau M2 (29/11) chỉ được:** sửa bug, làm đẹp UI, viết tài liệu, và làm điểm cộng đã được duyệt. Mọi thay đổi interface sau M0 phải theo quy trình ở A7.

<a id="a3"></a>
## A3. Vai trò và trách nhiệm

| Người | Vai trò chính | Sở hữu (chịu trách nhiệm cuối) | Review PR của |
|---|---|---|---|
| **Sơn** | Lead, Smart contract core, DevOps | `AMMPair`, `AMMRouter`, deploy/seed, `dev.sh`, Sepolia, ghép hệ thống, quyết định kỹ thuật | Mọi PR contract và hạ tầng; duyệt cuối mọi PR |
| **Minh** | Smart contract token và DeFi | `TestToken`, `DEXToken`, `StakingRewards`, `DEXGovernor` + Timelock, `DEXRegistry`, trang Governance | Router/Pair (review chéo với Sơn) |
| **Nhàn** | Frontend, sản phẩm, demo | Khung frontend, design, trang Swap và Pool, `demo-script.md`, slide, video | Mọi PR frontend |
| **Quyền** | Backend, IPFS, mã hóa, biên tập báo cáo | Backend, crypto, IPFS, token list, trang History & Receipts, `audit_cli`, file báo cáo tổng | PR backend; PR có đụng tới crypto |

**Nguyên tắc sở hữu theo lát dọc:** người làm tính năng nào thì chịu trách nhiệm tính năng đó từ contract/backend tới giao diện và chương báo cáo tương ứng. Minh làm trang Governance và Quyền làm trang Receipts, nhưng dùng component và quy ước của Nhàn, và Nhàn review.

**Lead làm mỗi tuần:**

- Giữ bảng task (GitHub Projects) đúng thực tế.
- Gỡ việc bị chặn trong ngày.
- Review PR trong vòng 24 giờ.
- Chủ trì họp tuần.
- Cập nhật rủi ro (A9).
- Quyết định khi có tranh luận kỹ thuật.

<a id="a4"></a>
## A4. Cách đọc một task và Definition of Done

**Mã task** có dạng `<NHÓM>-<SỐ>`. Mỗi task là một GitHub Issue có tiêu đề `[<mã>] <tên>`, nằm trong milestone M0-M3 và GitHub Project của nhóm. Issue được sinh từ PLAN bằng `scripts/github/sync_issues.py`: sửa PLAN rồi chạy lại script, không sửa tay nội dung issue.

| Nhóm | Nghĩa |
|---|---|
| `ALL` | Cả nhóm |
| `SC` | Smart contract |
| `FE` | Frontend |
| `BE` | Backend / IPFS / crypto |
| `DV` | Hạ tầng, deploy, script |
| `QA` | Kiểm thử, tích hợp, demo |
| `DOC` | Báo cáo, slide, video |
| `PM` | Quản lý |

Số task: `0x` là tuần 0, `1x` là tuần 1, v.v.

**Mỗi task gồm các trường:**

- **Hạn / Ước lượng / Phụ thuộc.** Phụ thuộc ghi theo mã task kèm số issue; trên GitHub cũng được nối bằng quan hệ "blocked by".
- **Mục tiêu:** làm task này để làm gì.
- **Input:** cần có gì trước khi bắt đầu (tài liệu, task khác, dữ liệu).
- **Hướng dẫn logic:** các bước tư duy, không phải code.
- **Output:** file hoặc sản phẩm phải có.
- **Done khi:** tiêu chí nghiệm thu, kiểm tra được.
- **Bẫy:** lỗi hay gặp (nếu có).

**Definition of Done chung** (áp dụng cho mọi task code, cộng thêm "Done khi" riêng của task):

1. Code nằm trên `main` qua PR đã được review và approve.
2. Có test cho logic mới. Contract dùng forge test, backend dùng pytest. Frontend: tự test tay theo checklist và ghi trong PR.
3. Không có secret trong code.
4. Chạy được bằng `scripts/dev.sh` trên máy người khác (người review thử).
5. Nếu đụng interface hoặc luồng dữ liệu thì cập nhật ARCHITECTURE.md trong cùng PR.
6. Chụp ảnh hoặc ghi lại minh chứng cho báo cáo (A8) nếu là tính năng nhìn thấy được.

**Ước lượng:** đơn vị "ngày" là khoảng 3-4 giờ làm việc tập trung của sinh viên. Nếu thấy task mất gấp đôi ước lượng thì **báo ngay trong standup**, đừng im lặng.

<a id="a5"></a>
## A5. Quy trình Git và review

**Nhánh:**

- `main` được bảo vệ: không push thẳng, phải qua PR có ít nhất 1 approve, CI xanh (khi có CI).
- Nhánh làm việc đặt tên `<nhóm>/<mã-task>-<mô-tả-ngắn>`, ví dụ `sc/SC-10-amm-pair`, `fe/FE-11-swap-page`.
- Mỗi task một nhánh, một PR. PR nhỏ (dưới ~400 dòng thay đổi nếu có thể). Task lớn thì chia nhiều PR.

**Commit:**

- Theo Conventional Commits, viết bằng tiếng Anh: `feat(pair): add fee-adjusted k check`, `fix(fe): use block timestamp for deadline`, `test(router): slippage revert`, `docs: update architecture 4.3`.
- Code, tên biến, comment trong code, commit message: **tiếng Anh**.
- Tài liệu trong `docs/` và báo cáo: **tiếng Việt**.

**Pull Request:**

- Tiêu đề: `[SC-10] AMMPair core`.
- Mô tả: làm gì, cách test, ảnh chụp (nếu có UI), checklist DoD.
- Gắn `Closes #<issue>` khi đã có issue.
- Người review: theo bảng A3. Review trong **24 giờ**. Nhận xét phải cụ thể; sửa xong thì người review resolve.
- Merge bằng **Squash and merge**.

**Đồng bộ:** trước khi tạo PR, rebase hoặc merge `main` mới nhất. Xung đột ở `deployments/*.json` thì chạy lại deploy, không sửa tay.

<a id="a6"></a>
## A6. Giao tiếp và họp

| Hình thức | Khi nào | Nội dung |
|---|---|---|
| **Standup viết** trong nhóm chat | Trước 21:00 mỗi ngày | 3 dòng: Hôm nay đã làm, Mai làm, Bị chặn bởi gì |
| **Họp tuần** (online, 45 phút) | CN 20:00 | Mỗi người demo phần đã xong (chạy thật, không chỉ nói), xem mốc, chia task tuần sau, cập nhật rủi ro |
| **Báo chặn** | Ngay khi bị chặn quá **4 giờ** | Nhắn tag người liên quan và Lead |
| **Quyết định kỹ thuật** | Khi cần | Ghi vào issue hoặc PR (không chỉ nói miệng); nếu đổi thiết kế thì sửa ARCHITECTURE.md |

**Quy tắc vàng:** "Xong" nghĩa là đã merge và người khác chạy được. "Gần xong" không được tính.

<a id="a7"></a>
## A7. Quy tắc kỹ thuật chung

**Môi trường:**

- Phiên bản công cụ ghim trong repo: `foundry.toml`, `.nvmrc`, `.python-version`, file lock của npm và Python.
- Không tự ý nâng phiên bản. Muốn nâng thì báo Lead.

**Ví và bí mật:**

- Dùng **một profile trình duyệt riêng** cho MetaMask dev. **Không bao giờ** dùng ví có tiền thật.
- Local chỉ dùng tài khoản mặc định của Anvil; thứ tự ví theo ARCHITECTURE 4.8 (#0 Admin … #5 Backend).
- Khóa Sepolia chỉ dành cho dev, lưu trong `.env` (đã nằm trong `.gitignore`). Repo chỉ có `.env.example` với giá trị giả.
- Lỡ commit secret: báo Lead ngay, **đổi khóa** (không chỉ xóa commit).

**Interface là hợp đồng giữa các nhánh:**

- Sau M0, mọi thay đổi chữ ký hàm, event hay lỗi của contract đều phải:
  1. mở PR có nhãn `interface-change`;
  2. được Lead duyệt;
  3. báo cho người dùng interface đó (frontend/backend);
  4. cập nhật ARCHITECTURE.md trong cùng PR.
- `deployments/<chain>.json` là **nguồn duy nhất** của địa chỉ và ABI. Frontend và backend đọc file này, không chép địa chỉ bằng tay.

**Dùng AI hỗ trợ:**

- Được dùng.
- Người commit phải **hiểu và giải thích được từng dòng**. Lead sẽ hỏi ngẫu nhiên khi review.
- Không dán private key, file `.env` hay dữ liệu cá nhân vào công cụ AI.

**Tiếng Việt trong UI:** giao diện bằng tiếng Việt, thuật ngữ chuyên môn giữ tiếng Anh (Swap, Pool, LP, TVL, Slippage).

<a id="a8"></a>
## A8. Thu thập minh chứng cho báo cáo

Làm **trong lúc** code, không để dồn về cuối.

- Thư mục `docs/report-assets/<mã-task>/`.
- Ảnh chụp đặt tên `<mã-task>-<nội-dung>.png`, kèm file `captions.md` ghi caption tiếng Việt cho từng ảnh (dạng "Hình: …").
- Cần chụp:
  - giao diện từng trang;
  - kết quả `forge test` (kèm `--gas-report`);
  - kết quả pytest;
  - giao dịch trên Etherscan (Sepolia);
  - file trên gateway IPFS;
  - màn hình 403 và 200 của RBAC;
  - log backend tạo biên lai.
- Link Sepolia (địa chỉ contract, tx hash) ghi vào `docs/report-assets/sepolia-links.md`.

<a id="a9"></a>
## A9. Rủi ro và dự phòng

| # | Rủi ro | Khả năng | Ảnh hưởng | Phòng ngừa | Kế hoạch B |
|---|---|---|---|---|---|---|
| R1 | Học Solidity chậm, contract trễ | Trung bình | Cao | Tuần 0 học có bài tập; interface chốt sớm; review chéo | Lead nhận bớt việc của Minh; Minh chuyển sang viết test |
| R2 | Frontend quá tải (một người) | Cao | Cao | Lát dọc: Minh làm trang Governance, Quyền làm trang Receipts | Sơn nhận phần Farm của trang Pool |
| R3 | Không xin được Sepolia ETH | Trung bình | Cao (TC1) | Xin ngay tuần 0, thử nhiều faucet, nhiều thành viên cùng xin rồi chuyển cho ví deployer | Hỏi giảng viên dùng testnet khác |
| R4 | Mã hóa Python ↔ trình duyệt không khớp | Trung bình | Trung bình | Thử nghiệm interop (BE-11) ngay tuần 1 | Giải mã ở backend, frontend chỉ hiển thị (ghi giới hạn vào báo cáo) |
| R5 | Demo lỗi giao dịch (MetaMask nonce, deadline, governance) | Trung bình | Cao | Các biện pháp ở ARCHITECTURE mục 6/7/10; tổng duyệt 3 lần | Video dự phòng; state Anvil lưu sẵn |
| R6 | RainbowKit/Pinata cần mạng | Thấp | Trung bình | Kiểm tra ở tuần 0 | Chỉ dùng wagmi injected connector, bỏ RainbowKit; bỏ Pinata khỏi demo |
| R7 | Thành viên bận đột xuất (thi, việc riêng) | Trung bình | Cao | Báo trước; task có tài liệu rõ để người khác nhận | Lead phân lại task trong họp tuần |
| R8 | Báo cáo dồn về cuối | Cao | Trung bình (TC5) | Template sẵn từ tuần 1; mỗi người viết nháp chương mình ở tuần 2 | Quyền điều phối, chấp nhận bản ngắn nhưng đúng format |

<a id="a10"></a>
## A10. Tài liệu học theo vai trò

| Ai | Đọc gì |
|---|---|
| Cả nhóm | ARCHITECTURE.md; Uniswap V2 Core whitepaper (mục 2-3); khái niệm DEX, AMM, Counterparty Risk trong sách *Understanding DeFi* (README) |
| Sơn, Minh | Solidity docs (docs.soliditylang.org); Foundry Book (book.getfoundry.sh): forge test, cheatcodes (`vm.prank`, `vm.warp`, `vm.roll`, `vm.expectRevert`), fuzz, invariant, forge script; OpenZeppelin Contracts v5 docs (ERC20, AccessControl, ReentrancyGuard, Governance) và OZ Wizard |
| Nhàn | wagmi docs (wagmi.sh), viem docs (viem.sh), RainbowKit docs; React + Vite |
| Quyền | FastAPI docs; web3.py docs (event, `get_logs`, gửi giao dịch); Kubo HTTP RPC (docs.ipfs.tech); thư viện `cryptography` (HKDF, AESGCM, RSA OAEP); MDN Web Crypto API; EIP-4361 (Sign-In with Ethereum); tokenlists.org |

---

# Phần B - Chi tiết theo tuần

Chi tiết từng người nằm trong `docs/plan/`: [Cả nhóm](plan/TEAM.PLAN.md) · [Sơn (Lead)](plan/SON.PLAN.md) · [Minh](plan/MINH.PLAN.md) · [Nhàn](plan/NHAN.PLAN.md) · [Quyền](plan/QUYEN.PLAN.md)

| Tuần | Mục tiêu tuần |
|---|---|
| Tuần 0 - Khởi động (T5 12/11 → CN 15/11) | cả 4 người chạy được môi trường; hiểu toán AMM; interface chốt (M0); rủi ro lớn (Sepolia ETH, OZ v5, RainbowKit offline, CID Kubo/Pinata) đã được kiểm chứng. |
| Tuần 1 - Lõi chạy local (T2 16/11 → CN 22/11) | trên Anvil, người dùng add liquidity → swap → remove **qua giao diện**. Token, Staking và Registry có test pass. Backend mã hóa được và đã kiểm chứng giải mã trên trình duyệt. |
| Tuần 2 - Đủ tính năng (T2 23/11 → CN 29/11) | mọi chức năng chạy end-to-end trên local; lên Sepolia (M2a, T6 27/11); feature freeze CN 29/11 kèm tổng duyệt lần 1. |
| Tuần 3 - Hoàn thiện (T2 30/11 → CN 06/12) | không còn lỗi chặn; demo ổn định qua 3 lần tổng duyệt; video có phụ đề; báo cáo và slide đạt checklist TC5; minh chứng Sepolia đầy đủ. |

---

<a id="c-summary"></a>
# Phần C - Bảng tổng hợp task

Nguồn để sinh GitHub Issues (`scripts/github/sync_issues.py`). Cột Issue dẫn tới issue tương ứng.

| Mã | Issue | Tên | Người | Hạn | Phụ thuộc | Milestone |
|---|---|---|---|---|---|---|
| PM-01 | [#1](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/1) | Họp kickoff | Sơn | 13/11 | - | M0 |
| PM-02 | [#2](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/2) | Hỏi giảng viên | Sơn | 13/11 | - | M0 |
| DV-01 | [#3](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/3) | Dựng repo và quy trình | Sơn | 12/11 | - | M0 |
| ALL-01 | [#4](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/4) | Cài môi trường | Cả nhóm | 13/11 | DV-01 ([#3](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/3)) | M0 |
| ALL-02 | [#5](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/5) | Bài tập toán AMM | Cả nhóm | 14/11 | - | M0 |
| ALL-03 | [#6](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/6) | Review ARCHITECTURE + PLAN | Cả nhóm | 14/11 | - | M0 |
| ALL-04 | [#7](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/7) | Học Foundry cơ bản | Minh | 15/11 | DV-01 ([#3](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/3)) | M0 |
| SC-01 | [#8](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/8) | Interface + chốt `interface-v1` | Sơn | 15/11 | DV-01 ([#3](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/3)), ALL-03 ([#6](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/6)) | M0 |
| SC-02 | [#9](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/9) | Kiểm chứng OZ v5 (Governor, DEXToken) | Minh | 15/11 | DV-01 ([#3](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/3)) | M0 |
| DV-02 | [#10](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/10) | Định dạng deployments + export | Sơn | 15/11 | SC-01 ([#8](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/8)) | M0 |
| DV-03 | [#11](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/11) | Xin Sepolia ETH | Sơn | 15/11 | - | M0 |
| FE-01 | [#12](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/12) | Khung frontend + ví + thử offline | Nhàn | 15/11 | DV-01 ([#3](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/3)) | M0 |
| FE-02 | [#13](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/13) | Wireframe 4 trang | Nhàn | 15/11 | - | M0 |
| BE-01 | [#14](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/14) | Khung backend + IPFS + so CID | Quyền | 15/11 | DV-01 ([#3](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/3)) | M0 |
| BE-02 | [#15](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/15) | Khóa RSA auditor + master key | Quyền | 15/11 | - | M0 |
| SC-10 | [#16](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/16) | AMMPair | Sơn | 18/11 | SC-01 ([#8](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/8)) | M1 |
| SC-11 | [#17](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/17) | AMMRouter | Sơn | 20/11 | SC-10 ([#16](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/16)) | M1 |
| SC-12 | [#18](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/18) | Fuzz + invariant | Sơn | 22/11 | SC-11 ([#17](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/17)) | M1 |
| DV-10 | [#19](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/19) | Deploy/Seed v1 + dev.sh v1 | Sơn | 22/11 | SC-11 ([#17](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/17)), SC-13 ([#20](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/20)), DV-02 ([#10](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/10)) | M1 |
| SC-13 | [#20](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/20) | TestToken | Minh | 17/11 | SC-01 ([#8](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/8)) | M1 |
| SC-14 | [#21](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/21) | DEXToken | Minh | 18/11 | SC-02 ([#9](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/9)) | M1 |
| SC-15 | [#22](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/22) | StakingRewards | Minh | 21/11 | SC-14 ([#21](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/21)) | M1 |
| SC-16 | [#23](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/23) | DEXRegistry | Minh | 22/11 | SC-01 ([#8](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/8)) | M1 |
| FE-10 | [#24](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/24) | Cấu hình contract + hooks chung | Nhàn | 17/11 | DV-02 ([#10](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/10)), FE-01 ([#12](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/12)) | M1 |
| FE-11 | [#25](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/25) | Trang Swap v1 | Nhàn | 22/11 | FE-10 ([#24](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/24)), SC-11 ([#17](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/17)) | M1 |
| FE-12 | [#26](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/26) | Header ví/mạng/faucet | Nhàn | 18/11 | FE-01 ([#12](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/12)), SC-13 ([#20](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/20)) | M1 |
| BE-10 | [#27](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/27) | Module crypto | Quyền | 18/11 | BE-02 ([#15](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/15)) | M1 |
| BE-11 | [#28](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/28) | Interop Python ↔ Web Crypto | Quyền | 20/11 | BE-10 ([#27](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/27)) | M1 |
| BE-12 | [#29](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/29) | Token list + logo lên IPFS | Quyền | 22/11 | BE-01 ([#14](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/14)), SC-16 ([#23](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/23)) | M1 |
| DOC-01 | [#30](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/30) | Template báo cáo/slide + dàn ý | Quyền | 22/11 | PM-02 ([#2](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/2)) | M1 |
| SC-20 | [#31](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/31) | Deploy/Seed đầy đủ + test quyền | Sơn | 24/11 | SC-14 ([#21](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/21)), SC-15 ([#22](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/22)), SC-16 ([#23](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/23)), SC-21 ([#36](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/36)) | M2 |
| DV-20 | [#32](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/32) | dev.sh đầy đủ + chain.sh | Sơn | 25/11 | SC-20 ([#31](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/31)), BE-12 ([#29](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/29)), BE-20 ([#44](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/44)) | M2 |
| DV-21 | [#33](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/33) | Deploy + verify Sepolia | Sơn | 27/11 | SC-20 ([#31](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/31)), DV-03 ([#11](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/11)) | M2 |
| QA-20 | [#34](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/34) | Tích hợp + phân loại bug | Sơn | 29/11 | - | M2 |
| QA-21 | [#35](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/35) | Tổng duyệt lần 1 | Cả nhóm | 29/11 | mọi task M2 | M2 |
| SC-21 | [#36](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/36) | Governor + Timelock + test E2E | Minh | 24/11 | SC-02 ([#9](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/9)), SC-14 ([#21](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/21)), SC-10 ([#16](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/16)) | M2 |
| SC-22 | [#37](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/37) | Rà bảo mật + NatSpec | Minh | 26/11 | SC-10 ([#16](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/16))..SC-21 ([#36](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/36)) | M2 |
| FE-21 | [#38](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/38) | Trang Governance | Minh | 29/11 | FE-10 ([#24](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/24)), SC-21 ([#36](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/36)), BE-21 ([#45](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/45)) | M2 |
| FE-20a | [#39](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/39) | Pool: thêm/rút thanh khoản | Nhàn | 24/11 | FE-10 ([#24](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/24)), SC-11 ([#17](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/17)) | M2 |
| FE-20b | [#40](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/40) | Pool: Dashboard | Nhàn | 26/11 | FE-20a ([#39](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/39)), SC-10 ([#16](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/16)) | M2 |
| FE-20c | [#41](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/41) | Pool: Farm | Nhàn | 28/11 | FE-20a ([#39](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/39)), SC-15 ([#22](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/22)) | M2 |
| FE-22 | [#42](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/42) | Ô memo trên Swap | Nhàn | 28/11 | FE-11 ([#25](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/25)), BE-20 ([#44](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/44)) | M2 |
| QA-22 | [#43](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/43) | Nháp demo-script | Nhàn | 29/11 | QA-20 ([#34](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/34)) | M2 |
| BE-20 | [#44](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/44) | Listener + biên lai + memo + hàng đợi | Quyền | 26/11 | BE-10 ([#27](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/27)), SC-11 ([#17](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/17)), SC-16 ([#23](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/23)), DV-10 ([#19](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/19)) | M2 |
| BE-21 | [#45](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/45) | Xác thực chữ ký + cấp khóa + upload PDF | Quyền | 27/11 | BE-20 ([#44](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/44)), SC-14 ([#21](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/21)) | M2 |
| FE-23 | [#46](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/46) | Trang History & Receipts | Quyền | 29/11 | FE-10 ([#24](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/24)), BE-11 ([#28](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/28)), BE-21 ([#45](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/45)) | M2 |
| BE-22 | [#47](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/47) | audit_cli | Quyền | 29/11 | BE-10 ([#27](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/27)) | M2 |
| QA-30 | [#48](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/48) | Bug bash chéo | Cả nhóm | 30/11 | QA-21 ([#35](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/35)) | M3 |
| PM-31 | [#49](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/49) | Cổng điểm cộng | Sơn | 01/12 | QA-21 ([#35](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/35)) | M3 |
| QA-32 | [#50](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/50) | Sửa bug contract + Governance | Minh | 01/12 | QA-30 ([#48](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/48)) | M3 |
| QA-33 | [#51](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/51) | demo-script bản chốt | Nhàn | 01/12 | QA-22 ([#43](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/43)) | M3 |
| QA-34 | [#52](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/52) | Sửa bug backend + Receipts | Quyền | 01/12 | QA-30 ([#48](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/48)) | M3 |
| QA-31 | [#53](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/53) | Minh chứng Sepolia đầy đủ | Sơn | 02/12 | DV-21 ([#33](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/33)) | M3 |
| FE-30 | [#54](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/54) | Hoàn thiện giao diện | Nhàn | 02/12 | QA-30 ([#48](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/48)) | M3 |
| DOC-36 | [#55](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/55) | Chương 5.3 | Quyền | 02/12 | - | M3 |
| DOC-30 | [#56](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/56) | Chương báo cáo của mỗi người | Cả nhóm | 03/12 | DOC-01 ([#30](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/30)) | M3 |
| DOC-31 | [#57](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/57) | Chương của Lead + duyệt cuối | Sơn | 03/12, 05/12 | DOC-37 ([#64](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/64)) | M3 |
| DOC-32 | [#58](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/58) | Chương 5.2 + test contract | Minh | 03/12 | - | M3 |
| DOC-33 | [#59](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/59) | Slide | Nhàn | 03/12 | DOC-01 ([#30](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/30)) | M3 |
| DOC-35 | [#60](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/60) | Chương 5.4 + Ch7 | Nhàn | 03/12 | - | M3 |
| DV-31 | [#61](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/61) | CI (điểm cộng) | Minh | 03/12 | PM-31 ([#49](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/49)) | M3 |
| PM-30 | [#62](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/62) | Chuẩn bị câu hỏi phản biện | Cả nhóm | 04/12 | - | M3 |
| DOC-34 | [#63](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/63) | Video có phụ đề | Nhàn | 04/12 | QA-33 ([#51](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/51)) | M3 |
| DOC-37 | [#64](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/64) | Biên tập báo cáo tổng | Quyền | 05/12 | DOC-30 ([#56](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/56)) | M3 |
| DV-30 | [#65](https://github.com/ThSonDev/IS355.R11-amm-dex/issues/65) | Đóng gói nộp, tag v1.0 | Sơn | 06/12 | mọi task | M3 |
