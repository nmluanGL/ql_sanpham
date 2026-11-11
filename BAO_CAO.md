# Báo cáo thực hành — Quản lý sản phẩm

## 1. Mục tiêu

Xây dựng phân hệ quản trị bằng Flutter. Quản trị viên đăng nhập bằng
Firebase Authentication, xem và tìm sản phẩm theo tên, thêm, sửa và xóa
sản phẩm. Web và Android dùng chung dữ liệu trên Cloud Firestore.

## 2. Kiến trúc

- `main.dart` khởi tạo Firebase và chuyển màn hình theo trạng thái đăng nhập.
- `login_screen.dart` đăng nhập email/mật khẩu.
- `products_screen.dart` đọc danh sách theo thời gian thực, tìm kiếm và xác nhận xóa.
- `product_form.dart` kiểm tra tên, giá, số lượng và chọn ảnh.
- `cloudinary_image_upload.dart` gửi ảnh tới Cloudinary và lấy `secure_url`.
- `product_service.dart` chuyển đối tượng sản phẩm thành dữ liệu Firestore.
- `firestore.rules` cấp quyền đọc/ghi cho UID quản trị và kiểm tra dữ liệu.

## 3. Cấu trúc dữ liệu

Collection `products` có đúng bốn trường trên mỗi document.

| Trường | Kiểu | Ý nghĩa |
| --- | --- | --- |
| name | string | Tên sản phẩm |
| price | number | Giá không âm |
| soluong | int | Số lượng tồn không âm |
| image | string | URL HTTPS của ảnh |

Firestore quản lý ID document bên ngoài bốn trường trên. Tệp `products.json`
chứa dữ liệu mẫu để minh họa định dạng nộp.

## 4. Cài đặt và chạy

Với project có sẵn, chạy `flutter pub get`. Lệnh tương đương khi bắt đầu
từ project Flutter mới là:

    flutter pub add firebase_core firebase_auth cloud_firestore http image_picker

Dự án đã có Firebase options cho Web và Android. Các bước bật Email/Password,
tạo tài khoản quản trị, cài CLI, cấu hình project khác và triển khai Rules
được ghi trong README.md. Tạo preset Unsigned trong Cloudinary, sau đó chạy:

    flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=TEN_CLOUD --dart-define=CLOUDINARY_UPLOAD_PRESET=TEN_PRESET

Với Android, dùng `flutter devices` để lấy ID thiết bị rồi thay `chrome`
bằng ID đó. Khi lưu, ứng dụng tải tệp ảnh lên Cloudinary trước và lưu URL
trả về trong Firestore.

## 5. Kịch bản demo và ảnh minh họa

1. Mở web và đăng nhập. Chụp màn hình đăng nhập với mật khẩu đã che.
2. Thêm sản phẩm, nhập giá và số lượng, chọn ảnh từ máy rồi lưu. Chụp danh sách.
3. Mở Firebase Console → Firestore Database → Data → products. Chụp một
   document có đủ bốn trường và URL Cloudinary.
4. Tìm theo tên, sửa số lượng, tải lại web và kiểm tra dữ liệu. Mở Android,
   chọn ảnh từ thư viện và kiểm tra sản phẩm xuất hiện trên web.
5. Xóa sản phẩm dùng để kiểm thử và xác nhận danh sách cập nhật.

## 6. Hồ sơ nộp

- Báo cáo này kèm ảnh chụp sau khi demo bằng tài khoản quản trị.
- Tệp JSON xuất từ dữ liệu thật trong Firestore. Xem định dạng trong `products.json`.
- Link GitHub: điền sau khi đẩy mã nguồn lên repo của người nộp.
- Link video demo: điền sau khi quay và tải video lên.
