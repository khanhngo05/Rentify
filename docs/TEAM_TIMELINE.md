# 📅 Kế hoạch & Phân công — Dự án Rentify

> **Môn:** Phát Triển Ứng Dụng Thiết Bị Di Động  
> **Đề tài:** Rentify — Ứng dụng cho thuê trang phục trực tuyến đa chi nhánh  
> **Lớp:** 65CNTT — Trường Đại học Thủy Lợi  
> **GitHub:** https://github.com/khanhngo05/Rentify

---

## 👥 Phân công nhiệm vụ

| Người | Họ và tên | MSSV | Phụ trách |
|-------|-----------|------|-----------|
| **P1** | Ngô Xuân Khánh | 2351060453 | Firebase + Core + Data + QA |
| **P2** | Lê Thị Như Quỳnh | 2351060484 | Home Screen + GPS Chi nhánh |
| **P3** | Lê Thu Giang | 2351060438 | Detail Screen + Yêu thích + Profile |
| **P4** | Nguyễn Quang Dũng | | Chức năng Thuê + Giỏ hàng |
| **P5** | Trần Vĩnh Bảo | | Auth + Lịch sử thuê + Đánh giá |

---

## 📋 Chi tiết nhiệm vụ từng người

### 👤 Người 1 — Firebase + Core + Data + QA
> **Vai trò:** Nền tảng của toàn bộ dự án. Mọi người đều phụ thuộc vào phần này.

**Setup & Cấu hình:**
- [ ] Tạo Firebase project, bật Firestore & Authentication
- [ ] Tạo Supabase project, tạo bucket `fashion-images`
- [ ] Chạy `flutterfire configure` để kết nối Flutter ↔ Firebase
- [ ] Cấu hình Supabase trong `main.dart`

**Core (dùng chung toàn nhóm):**
- [ ] Viết toàn bộ **Models**: `UserModel`, `Product`, `Branch`, `Order`, `Review`, `Favorite`
- [ ] Viết **AppTheme**: màu sắc (#, font Outfit, TextStyle, ButtonStyle...)
- [ ] Viết **AppConstants**: tên routes, strings, category list...
- [ ] Viết **Shared Widgets**: `ProductCard`, `LoadingWidget`, `ErrorWidget`, `CustomButton`
- [ ] Viết **FirebaseService**: CRUD sản phẩm, chi nhánh, tồn kho
- [ ] Viết **SupabaseService**: upload/download ảnh

**Dữ liệu mẫu (Seed data):**
- [ ] Thêm ít nhất **3 chi nhánh** (Đống Đa, Cầu Giấy, Thanh Xuân) với tọa độ GPS thực
- [ ] Thêm ít nhất **15–20 sản phẩm** đầy đủ thông tin:
  - Quần, Áo, Váy, Giày dép, Phụ kiện
  - Mỗi sản phẩm có: tên, mô tả, giá/ngày, tiền cọc, ảnh, size, màu, danh mục
- [ ] Thiết lập tồn kho từng chi nhánh cho từng sản phẩm

**Cuối dự án (QA):**
- [ ] Merge code từ tất cả thành viên
- [ ] Giải quyết conflict
- [ ] Kiểm tra luồng từ đầu đến cuối
- [ ] Fix bug, tối ưu hiệu năng

---

### 👤 Người 2 — Home Screen + GPS Chi nhánh
> **Bắt đầu:** Sau khi P1 push models + services lên GitHub

**Home Screen:**
- [ ] AppBar với logo Rentify + icon giỏ hàng góc phải
- [ ] GridView 2 cột hiển thị danh sách sản phẩm
- [ ] Dùng `ProductCard` (widget từ P1) cho mỗi ô sản phẩm
- [ ] Thanh tìm kiếm (theo tên, danh mục)
- [ ] Filter theo danh mục: Quần / Áo / Váy / Giày / Phụ kiện
- [ ] Gọi dữ liệu từ `FirebaseService` (P1 viết)
- [ ] Xử lý trạng thái: Loading → Data → Error (dùng Shimmer)

**GPS — Gợi ý chi nhánh gần nhất:**
- [ ] Màn hình danh sách chi nhánh
- [ ] Xin quyền GPS của người dùng (`geolocator`)
- [ ] Tính khoảng cách từ user đến từng chi nhánh
- [ ] Sắp xếp và hiển thị: "Chi nhánh Đống Đa — cách bạn 1.2 km"
- [ ] Hiển thị giờ mở cửa và trạng thái (Đang mở / Đã đóng)

---

### 👤 Người 3 — Detail Screen + Yêu thích + Profile
> **Bắt đầu:** Sau khi P1 push models lên GitHub

**Detail Screen:**
- [ ] Ảnh sản phẩm lớn (PageView nếu có nhiều ảnh)
- [ ] Tên sản phẩm, danh mục, thương hiệu
- [ ] Giá thuê / ngày + tiền đặt cọc
- [ ] Mô tả chi tiết
- [ ] Chọn size, chọn màu
- [ ] Điểm đánh giá + số lượt review
- [ ] Nút **"Thuê Ngay"** → chuyển sang màn hình thuê (P4)
- [ ] Icon tim ❤️ để thêm vào yêu thích

**Tính năng Yêu thích:**
- [ ] Thêm / xóa sản phẩm yêu thích (lưu vào Firestore)
- [ ] Màn hình danh sách sản phẩm đã yêu thích

**Profile Screen:**
- [ ] Hiển thị ảnh đại diện, tên, email, số điện thoại
- [ ] Chỉnh sửa thông tin cá nhân
- [ ] Nút Đăng xuất
- [ ] Điều hướng đến Lịch sử thuê, Yêu thích

---

### 👤 Người 4 — Chức năng Thuê + Giỏ hàng
> **Bắt đầu:** Sau khi P3 có màn hình Detail (nút "Thuê Ngay")

**Màn hình Đặt thuê:**
- [ ] Hiển thị thông tin trang phục đã chọn (size, màu)
- [ ] Date picker: chọn **Ngày bắt đầu thuê**
- [ ] Date picker: chọn **Ngày trả**
- [ ] Tự động tính **Số ngày thuê** = ngày trả − ngày bắt đầu
- [ ] Tự động tính **Tổng tiền thuê** = giá/ngày × số ngày
- [ ] Hiển thị **Tiền đặt cọc**
- [ ] Nhập địa chỉ giao nhận
- [ ] Nút "Thêm vào Giỏ" / "Thuê Ngay"

**Giỏ hàng:**
- [ ] Danh sách trang phục đã thêm vào giỏ
- [ ] Hiển thị: tên, ảnh, size, màu, số ngày, thành tiền
- [ ] Tính tổng tiền thuê + tổng tiền cọc tự động
- [ ] Thay đổi số lượng / xóa khỏi giỏ
- [ ] Nút "Xác nhận đặt thuê" → tạo đơn trên Firestore
- [ ] Chọn chi nhánh thực hiện đơn thuê

---

### 👤 Người 5 — Auth + Lịch sử thuê + Đánh giá
> **Auth:** Bắt đầu ngay sau P1 setup Firebase Auth  
> **Lịch sử + Đánh giá:** Bắt đầu sau khi P4 hoàn thiện Giỏ hàng

**Đăng nhập / Đăng ký:**
- [ ] Màn hình Splash (logo Rentify)
- [ ] Màn hình Đăng nhập (email + mật khẩu)
- [ ] Màn hình Đăng ký (tên, email, số điện thoại, mật khẩu)
- [ ] Validate form (email hợp lệ, mật khẩu tối thiểu 6 ký tự)
- [ ] Xử lý lỗi (sai mật khẩu, email đã tồn tại...)
- [ ] Chuyển hướng sau đăng nhập thành công

**Lịch sử thuê:**
- [ ] Danh sách đơn thuê của người dùng (sắp xếp mới nhất)
- [ ] Hiển thị trạng thái đơn bằng màu sắc:
  - 🟡 Chờ xác nhận | 🔵 Đã xác nhận | 🟢 Đang thuê | ⚪ Đã trả | ✅ Hoàn thành | ❌ Đã hủy
- [ ] Xem chi tiết đơn thuê
- [ ] Hủy đơn (khi đang ở trạng thái "Chờ xác nhận")

**Đánh giá (sau khi trả đồ):**
- [ ] Form đánh giá: điểm sao (1–5) + nội dung nhận xét
- [ ] **Tích hợp Camera**: chụp ảnh thực tế trang phục
- [ ] Chọn ảnh từ thư viện (tùy chọn)
- [ ] Upload ảnh lên Supabase Storage
- [ ] Lưu đánh giá vào Firestore
- [ ] Hiển thị danh sách đánh giá ở màn hình Detail (P3)

---

## 🔄 Thứ tự & Timeline (7 ngày)

```
         Ngày 1   Ngày 2   Ngày 3   Ngày 4   Ngày 5   Ngày 6   Ngày 7
         ───────  ───────  ───────  ───────  ───────  ───────  ───────
P1 (QY) [SETUP & CORE & DATA     ][░░░░░░░░░░░░░░░░░░][REVIEW & FIX  ]
P2 (GI)          [CHỜP1  ][HOME SCREEN & GPS          ][░░░  ]
P3 (KH)          [CHỜP1  ][DETAIL + YÊU THÍCH + PROFILE       ][░░░  ]
P4 (BẢO)         [CHỜP1  ][░░░░░░  ][THUÊ + GIỎ HÀNG           ][░░░]
P5 (DŨ)          [CHỜP1  ][AUTH UI ][░░░░░░  ][LỊCH SỬ + ĐÁNH GIÁ  ]
```

### 📆 Chi tiết từng ngày

| Ngày | Công việc | Ai làm |
|------|-----------|--------|
| **Ngày 1** | Setup Firebase + Supabase + Core models + Theme | P1 |
| **Ngày 2** | Seed data + FirebaseService + Shared widgets | P1 |
|  | *(P2, P3, P4, P5: đọc docs, cài đặt môi trường)* | P2–P5 |
| **Ngày 3** | P1 **push code lên GitHub** → các người khác bắt đầu | TẤT CẢ |
|  | Home Screen (P2) · Detail Screen (P3) · Auth UI (P5) | P2, P3, P5 |
| **Ngày 4** | GPS Chi nhánh (P2) · Yêu thích + Profile (P3) · Auth hoàn thiện (P5) | P2, P3, P5 |
|  | P3 xong nút "Thuê" → P4 bắt đầu | P4 bắt đầu |
| **Ngày 5** | Giỏ hàng + Đặt thuê (P4) · Lịch sử thuê (P5) | P4, P5 |
| **Ngày 6** | Đánh giá + Camera (P5) · Hoàn thiện tính năng còn lại | P4, P5, P2, P3 |
|  | P1 bắt đầu merge code, fix conflict | P1 |
| **Ngày 7** | Review tổng · Fix bug · Test luồng đầy đủ · Làm slide | P1 + cả nhóm |

---

## ⚙️ Quy tắc làm việc nhóm

### Git workflow
```
main branch      ← Chỉ P1 merge vào, code đã test
feature branches ← Mỗi người làm trên branch của mình
```

| Người | Branch |
|-------|--------|
| P1 | `main` (trực tiếp) |
| P2 | `feature/home-screen` |
| P3 | `feature/detail-screen` |
| P4 | `feature/rental-cart` |
| P5 | `feature/auth-history` |

### Quy tắc commit
```
feat: thêm tính năng mới
fix:  sửa bug
ui:   thay đổi giao diện
docs: cập nhật tài liệu
```
**Ví dụ:** `feat: thêm gridview home screen với filter danh mục`

### ⚠️ Lưu ý quan trọng

1. **Không được sửa** file trong `lib/models/` và `lib/services/` nếu không phải P1
2. Mỗi khi xong một màn hình → **push ngay** lên GitHub và báo nhóm
3. Nếu cần thêm field vào model → **báo P1** trước khi tự sửa
4. **Kéo code mới nhất** (`git pull`) trước khi bắt đầu làm mỗi ngày
5. Test trên thiết bị Android thực (hoặc emulator) trước khi push

---

## 📦 Dependencies cần cài (đã có trong pubspec.yaml)

```yaml
firebase_core, firebase_auth, cloud_firestore  # Firebase
supabase_flutter                                # Supabase (ảnh)
geolocator, geoflutterfire_plus                 # GPS
image_picker                                    # Camera + thư viện ảnh
cached_network_image, shimmer                  # Hiển thị ảnh + loading
go_router                                       # Điều hướng màn hình
intl                                            # Định dạng ngày tháng, tiền
```

**Cài đặt:**
```bash
flutter pub get
```

---

## 🔗 Tài nguyên

- **GitHub:** https://github.com/khanhngo05/Rentify
- **Thiết kế CSDL:** `docs/DATABASE_DESIGN.md`
- **Dữ liệu mẫu:** `docs/sample_data.json`
- **Firestore Rules:** `firestore.rules`
