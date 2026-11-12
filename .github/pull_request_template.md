## Làm gì

<!-- Mô tả ngắn. Tiêu đề PR: [MÃ-TASK] Tên task -->

Closes #

## Cách test

<!-- Lệnh đã chạy, kết quả. Ảnh chụp nếu có UI. -->

## Checklist Definition of Done

- [ ] Có test cho logic mới (contract: `forge test`, backend: `pytest`, frontend: checklist tay ghi ở trên)
- [ ] Không có secret trong code
- [ ] Chạy được bằng `scripts/dev.sh` (người review thử)
- [ ] Đã cập nhật `docs/ARCHITECTURE.md` nếu đụng interface hoặc luồng dữ liệu (đổi chữ ký hàm/event: gắn nhãn `interface-change`)
- [ ] Đã chụp ảnh/ghi lại minh chứng cho báo cáo nếu là tính năng nhìn thấy được
- [ ] Đạt tiêu chí "Done khi" riêng của task
