# 🤖 Hướng dẫn Setup AI Chatbot

Rentify sử dụng **Hybrid Chatbot** với 2 lớp:
1. **Local FAQ**: Trả lời nhanh các câu hỏi thường gặp (offline)
2. **Gemini AI**: Xử lý câu hỏi phức tạp (cần internet + API key)

---

## 🚀 Quick Start (Không cần API key)

Chatbot **đã hoạt động ngay** mà không cần cấu hình gì thêm!

- ✅ FAQ local có sẵn 15+ câu hỏi thường gặp
- ✅ Trả lời về giá, cách thuê, chi nhánh, chính sách...
- ❌ Không hiểu câu hỏi phức tạp/ngữ cảnh

---

## 🧠 Bật Gemini AI (Khuyên dùng)

Để chatbot thông minh hơn, bật Gemini AI:

### Bước 1: Lấy API Key miễn phí

1. Truy cập: https://makersuite.google.com/app/apikey
2. Đăng nhập bằng tài khoản Google
3. Click **"Create API Key"**
4. Copy API key

> 💡 **Miễn phí**: 60 requests/phút, đủ cho demo và sử dụng nhẹ

### Bước 2: Cấu hình trong code

Mở file `lib/services/chat_service.dart`, tìm dòng:

```dart
static const String _apiKey = 'YOUR_GEMINI_API_KEY';
```

Thay bằng API key của bạn:

```dart
static const String _apiKey = 'AIzaSy...your-key-here...';
```

### Bước 3: Chạy lại app

```bash
flutter run
```

---

## 🔒 Bảo mật API Key (Production)

⚠️ **KHÔNG commit API key lên Git!**

### Cách 1: Environment Variables (Khuyên dùng)

```dart
// chat_service.dart
static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
```

Chạy app:
```bash
flutter run --dart-define=GEMINI_API_KEY=your-key-here
```

### Cách 2: Sử dụng file .env

1. Thêm package `flutter_dotenv`
2. Tạo file `.env` (thêm vào .gitignore)
3. Load key từ .env

### Cách 3: Firebase Remote Config

Lưu key trên Firebase, fetch khi app khởi động.

---

## 📝 Tùy chỉnh FAQ

### Thêm câu hỏi mới

Mở `lib/services/chat_service.dart`, thêm vào `_faqDatabase`:

```dart
FAQItem(
  id: 'custom_1',
  keywords: ['từ khóa 1', 'từ khóa 2'],
  question: 'Câu hỏi hiển thị',
  answer: 'Câu trả lời của bạn',
  category: 'custom',
),
```

### Sửa gợi ý nhanh

Tìm method `getQuickSuggestions()`:

```dart
List<String> getQuickSuggestions() {
  return const [
    'Câu gợi ý 1',
    'Câu gợi ý 2',
    // ...
  ];
}
```

### Sửa System Prompt (AI personality)

Tìm `_systemPrompt` và chỉnh sửa theo ý muốn.

---

## 🎨 Tùy chỉnh UI

File: `lib/screens/messages_screen.dart`

- Màu sắc: Sửa trong `AppColors`
- Icon chatbot: Tìm `Icons.smart_toy_rounded`
- Welcome message: Tìm `'Xin chào! 👋'`
- AI badge: Tìm `'Gemini AI'`

---

## 🧪 Test Chatbot

### Câu hỏi FAQ (trả lời ngay):
- "Giá thuê bao nhiêu?"
- "Làm sao để thuê?"
- "Chi nhánh ở đâu?"
- "Chính sách hủy đơn"

### Câu hỏi AI (cần Gemini):
- "Tôi cao 1m65, nặng 55kg, nên chọn size gì?"
- "Gợi ý váy cưới cho đám cưới ngoài trời"
- "So sánh áo dài và hanbok"

---

## 🐛 Troubleshooting

### Lỗi: "AI đang bảo trì"
- Chưa cấu hình API key
- API key không hợp lệ
- Hết quota free tier

### Lỗi: Timeout
- Kiểm tra kết nối internet
- Gemini đang quá tải, thử lại sau

### Lỗi: Không hiểu câu hỏi
- Thêm keywords vào FAQ database
- Hoặc bật Gemini AI

---

## 📊 Monitoring

Theo dõi usage tại: https://console.cloud.google.com/apis

---

## 📚 Tài liệu tham khảo

- [Gemini API Documentation](https://ai.google.dev/docs)
- [google_generative_ai package](https://pub.dev/packages/google_generative_ai)
- [Firebase Remote Config](https://firebase.google.com/docs/remote-config)

---

**Happy Chatting! 🎉**
