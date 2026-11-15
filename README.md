# STV Reader Native – iPhone 11

Đây là **ứng dụng iOS native SwiftUI/UITextView/AVSpeechSynthesizer**, không chứa WebKit, không phải trình duyệt nhúng.

## Có thể sử dụng
- Giao diện thư viện sách tiếng Việt.
- Nhập tệp **.txt** và **.md** bằng Files trên iPhone.
- Tạo sách bằng cách dán nội dung.
- Đọc **offline**, tự lưu tiến độ, đánh dấu sách.
- Thay cỡ chữ, chọn nền sáng/giấy ấm/tối.
- Giọng đọc tiếng Việt bằng công cụ TTS của iOS.
- Tìm sách trong thư viện, xóa sách.

## Giới hạn
- KHÔNG phải STV MobileReader chính thức và không có mã nguồn iOS đầy đủ của nhà phát triển.
- Không đồng bộ tài khoản Sáng Tác Việt, không tìm hay tải truyện trực tuyến từ API của trang, chưa hỗ trợ EPUB hoặc đăng nhập.
- Chỉ hỗ trợ TXT/Markdown; tệp tải về có thể nhập bằng ứng dụng Tệp.
- IPA build qua GitHub Actions là **chưa ký**; cần Sideloadly ký mới cài được trên iPhone 11.
- Mã nguồn đã được kiểm tra qua Xcode CI nhưng chưa được chạy thử trên thiết bị thật.

## Build
GitHub Actions > Build iOS IPA > Artifacts > STVReader-Native-unsigned-IPA.
