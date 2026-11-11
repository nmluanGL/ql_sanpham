# Quản lý sản phẩm

Ứng dụng Flutter quản lý sản phẩm trên Web và Android. Firebase Authentication xác thực người dùng, Cloud Firestore lưu thông tin sản phẩm và Cloudinary lưu ảnh. Hai nền tảng dùng chung collection `products`.

- Đăng nhập và đăng xuất bằng email.
- Xem thống kê tồn kho, tìm sản phẩm theo tên.
- Thêm, sửa và xóa sản phẩm. Có thể chọn ảnh từ thiết bị hoặc nhập URL HTTPS.

Xem [tệp JSON minh họa cấu trúc dữ liệu](products.json).

## Cấu trúc mã nguồn

| File | Chức năng |
| --- | --- |
| `lib/main.dart` | Khởi tạo Firebase và chọn màn hình theo phiên đăng nhập |
| `lib/login_screen.dart` | Màn hình đăng nhập |
| `lib/products_screen.dart` | Tổng quan kho, danh sách và tìm kiếm |
| `lib/product_form.dart` | Form thêm, sửa và xem trước ảnh |
| `lib/product_service.dart` | Đọc và ghi bốn trường sản phẩm trên Firestore |
| `lib/cloudinary_image_upload.dart` | Tải ảnh lên Cloudinary và nhận URL |

## Chuẩn bị công cụ

Dự án được tạo với Flutter 3.47.6 và Dart 3.13.5. Cài Flutter stable tương thích, Chrome, Android SDK qua Android Studio và Firebase CLI. Với Android, khởi động máy ảo có Google Play hoặc bật USB debugging trên điện thoại.

```powershell
flutter doctor
flutter devices
flutter pub get
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

Lệnh thêm thư viện vào dự án mới là `flutter pub add firebase_core firebase_auth cloud_firestore`. Bản nộp đã khai báo chúng trong `pubspec.yaml`, vì vậy dùng `flutter pub get` khi lấy mã nguồn.

## Cấu hình Firebase

1. Trong Firebase Console, tạo hoặc chọn một project bạn quản lý. Mở **Authentication → Sign-in method**, bật **Email/Password**. Mở **Users → Add user**, nhập email và mật khẩu trực tiếp trong Console rồi sao chép **User UID**. Nếu Chrome báo lỗi miền, kiểm tra **Authentication → Settings → Authorized domains** và thêm miền chạy demo nếu cần.
2. Mở **Firestore Database → Create database**, chọn database mặc định và khởi tạo ở chế độ Production. Collection `products` xuất hiện sau lần lưu đầu.
3. Quyền đọc và ghi được cấu hình theo UID admin trong `firestore.rules`. Nếu dùng một dự án Firebase mới, cập nhật UID trong tệp trước khi triển khai.
4. Chạy các lệnh dưới đây tại thư mục chứa `pubspec.yaml`. Thay `PROJECT_ID` bằng ID thật. Nếu lệnh `flutterfire` chưa có trong PATH, thêm thư mục `bin` của Dart Pub Cache hoặc dùng `dart pub global run flutterfire_cli:flutterfire` thay thế.

```powershell
flutterfire configure --project=PROJECT_ID --platforms=web,android --yes
firebase deploy --only firestore:rules --project PROJECT_ID
```

FlutterFire tạo `lib/firebase_options.dart` cho hai nền tảng. Cấu hình đi kèm trỏ đến `quanlysanpham-7e79a`.

Khi thêm hoặc sửa sản phẩm, bấm ô **Thêm ảnh** để chọn tệp hoặc dán URL HTTPS vào ô **Link ảnh**. Firestore lưu URL vào trường `image` và ứng dụng tải ảnh từ URL đó. Nếu giữ nguyên ô này khi sửa, sản phẩm tiếp tục dùng ảnh cũ.

## Chạy ứng dụng

```powershell
flutter analyze
flutter test
flutter run -d chrome
flutter devices
flutter run -d DEVICE_ID
```

Thay `DEVICE_ID` bằng ID Android từ `flutter devices`. Đăng nhập bằng tài khoản đã tạo trong Console. Trên Web, thêm một sản phẩm có ảnh rồi tải lại trang để kiểm tra dữ liệu. Trên Android, mở ứng dụng trỏ đến cùng project, dán URL ảnh và kiểm tra sản phẩm xuất hiện ở cả hai nền tảng.

Nếu Gradle báo thiếu NDK 28.2.13676358, mở Android Studio → SDK Manager → SDK Tools, bật Show Package Details rồi cài đúng bản NDK (Side by side). Chạy lại `flutter doctor` và `flutter run -d DEVICE_ID`.


## Chọn ảnh từ máy với Cloudinary

Bản demo đã có cấu hình mặc định. Nếu dùng Cloudinary riêng, tạo Upload preset ở chế độ Unsigned. Giới hạn preset cho ảnh sản phẩm và dung lượng phù hợp. Dùng Cloud name và tên preset trong lệnh chạy. Không đặt API secret trong app. Preset unsigned có thể được gọi từ bên ngoài app, vì vậy chỉ bật preset khi cần dùng.

    flutter run -d DEVICE_ID --dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME --dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_PRESET

Khi chọn tệp rồi lưu, app gửi ảnh lên Cloudinary và ghi URL HTTPS trả về vào Firestore. Nếu chưa cấu hình Cloudinary, có thể tiếp tục dán link HTTPS.
