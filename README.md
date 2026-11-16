# STV Reader Native – SwiftUI iOS (không WebView)

**Đây là dự án ứng dụng iPhone native độc lập**, không phải ứng dụng STV MobileReader chính thức hay bản sao nhị phân. Không sử dụng WKWebView, Cordova hoặc Capacitor để hiển thị giao diện.

## Đã triển khai
- Thư viện TXT/Markdown **ngoại tuyến** trên iPhone, lưu vị trí đọc, ghi nhớ sách và giọng đọc tiếng Việt qua AVSpeechSynthesizer.
- Tab **Tìm STV**: truy vấn API danh mục công khai của `https://sangtacviet.com/io/searchtp/searchBooks` bằng URLSession, không tải trang web vào ứng dụng.
- Trang chi tiết truyện và danh sách chương từ endpoint công khai `https://sangtacviet.com/index.php?ngmar=chapterlist`.
- Màn hình đọc chương native, có thông báo khi STV từ chối yêu cầu vì định danh nền tảng.

## Giới hạn quan trọng
- **Chưa hỗ trợ đăng nhập và đồng bộ tài khoản STV**. Ứng dụng không thu thập mật khẩu vì chưa có tài liệu giao thức xác thực iOS phù hợp.
- API nội dung chương của STV có thể trả `Platform unknown, please check your device.` cho một client không phải bản phát hành chính thức; không thể bảo đảm xem chương trực tuyến trong bản thử nghiệm. Không giả lập hoặc làm giả mã định danh máy chủ.
- Nguồn web của STV có thể thay đổi, đây không phải API ổn định được nhà phát triển công bố.
- Muốn hoàn thiện đầy đủ đọc online/đăng nhập/đồng bộ phải có SDK/API hoặc hỗ trợ tương thích từ nhà phát triển STV.
- IPA xuất từ GitHub Actions chưa ký; sử dụng Sideloadly trên Windows để ký bằng Apple ID trước khi cài.
- Cần kiểm thử thực tế trên iPhone trước khi xác nhận chức năng.

## Build
Mở GitHub Actions -> `Build STV Reader Native STV Catalog IPA` -> Artifacts và tải IPA.
