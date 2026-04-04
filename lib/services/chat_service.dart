/// Chat Service - Hybrid FAQ + Gemini AI
///
/// Cung cấp chatbot thông minh với 2 lớp:
/// 1. Local FAQ: Trả lời nhanh các câu hỏi thường gặp
/// 2. Gemini AI: Xử lý các câu hỏi phức tạp, ngữ cảnh

import 'package:google_generative_ai/google_generative_ai.dart';

/// Model cho một câu hỏi FAQ
class FAQItem {
  final String id;
  final List<String> keywords;
  final String question;
  final String answer;
  final String category;

  const FAQItem({
    required this.id,
    required this.keywords,
    required this.question,
    required this.answer,
    required this.category,
  });
}

/// Service xử lý chatbot
class ChatService {
  // Gemini API Key - Thay bằng key của bạn
  // Lấy key miễn phí tại: https://makersuite.google.com/app/apikey
  static const String _apiKey = 'AIzaSyBS3NSD5fioGf61VSetC83vbBap_Fpm9P4';

  GenerativeModel? _model;
  ChatSession? _chatSession;

  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  /// Khởi tạo Gemini model
  void _initGemini() {
    if (_apiKey == 'AIzaSyBS3NSD5fioGf61VSetC83vbBap_Fpm9P4') {
      // Chưa có API key, sẽ chỉ dùng FAQ local
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.text(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 500,
      ),
    );
    _chatSession = _model!.startChat();
  }

  /// System prompt để "dạy" AI về Rentify
  static const String _systemPrompt = '''
Bạn là trợ lý AI của Rentify - ứng dụng cho thuê trang phục trực tuyến.

THÔNG TIN VỀ RENTIFY:
- Cho thuê: áo dài, váy cưới, đầm dạ hội, vest, hanbok, trang phục dân tộc
- Giá thuê: từ 150,000đ - 800,000đ/ngày tùy loại
- Tiền cọc: 30-50% giá trị trang phục
- Có nhiều chi nhánh tại Hà Nội
- Hỗ trợ: thuê online, thử đồ tại cửa hàng, giao hàng tận nơi

QUY TRÌNH THUÊ:
1. Chọn sản phẩm trên app
2. Chọn ngày thuê (bắt đầu - kết thúc)
3. Chọn chi nhánh lấy/trả đồ
4. Thanh toán tiền thuê + cọc
5. Nhận đồ và sử dụng
6. Trả đồ đúng hạn, nhận lại tiền cọc

CHÍNH SÁCH:
- Đặt trước ít nhất 24h
- Hủy trước 24h: hoàn tiền 100%
- Trả muộn: phạt 50% giá thuê/ngày
- Hư hỏng: trừ vào tiền cọc

GIỜ MỞ CỬA:
- Thứ 2-7: 8:00 - 21:00
- Chủ nhật: 9:00 - 18:00

CÁCH TRẢ LỜI:
- Ngắn gọn, thân thiện, dùng tiếng Việt
- Tối đa 2-3 câu cho mỗi câu trả lời
- Gợi ý người dùng khám phá app
- Không bịa thông tin không chắc chắn
''';

  /// Database FAQ local
  static const List<FAQItem> _faqDatabase = [
    // === GIỚI THIỆU ===
    FAQItem(
      id: 'intro_1',
      keywords: ['rentify', 'là gì', 'giới thiệu', 'về'],
      question: 'Rentify là gì?',
      answer:
          'Rentify là ứng dụng cho thuê trang phục trực tuyến, giúp bạn dễ dàng thuê áo dài, váy cưới, đầm dạ hội, vest và nhiều loại trang phục khác với giá hợp lý.',
      category: 'intro',
    ),

    // === GIÁ CẢ ===
    FAQItem(
      id: 'price_1',
      keywords: ['giá', 'bao nhiêu', 'tiền', 'phí', 'chi phí'],
      question: 'Giá thuê trang phục bao nhiêu?',
      answer:
          'Giá thuê từ 150,000đ - 800,000đ/ngày tùy loại trang phục. Áo dài khoảng 150-300k, váy cưới 400-800k, vest 200-400k/ngày.',
      category: 'pricing',
    ),
    FAQItem(
      id: 'price_2',
      keywords: ['cọc', 'đặt cọc', 'tiền cọc'],
      question: 'Tiền cọc là bao nhiêu?',
      answer:
          'Tiền cọc thường bằng 30-50% giá trị trang phục. Bạn sẽ nhận lại đầy đủ khi trả đồ đúng hạn và không hư hỏng.',
      category: 'pricing',
    ),
    FAQItem(
      id: 'price_3',
      keywords: ['thanh toán', 'trả tiền', 'payment'],
      question: 'Thanh toán như thế nào?',
      answer:
          'Bạn có thể thanh toán online qua ví điện tử, chuyển khoản, hoặc trả tiền mặt khi nhận đồ tại cửa hàng.',
      category: 'pricing',
    ),

    // === QUY TRÌNH THUÊ ===
    FAQItem(
      id: 'process_1',
      keywords: ['thuê', 'cách thuê', 'đặt', 'làm sao'],
      question: 'Làm sao để thuê trang phục?',
      answer:
          'Rất đơn giản: Chọn sản phẩm → Chọn ngày thuê → Chọn chi nhánh → Thanh toán → Nhận đồ. Tất cả thực hiện trên app!',
      category: 'process',
    ),
    FAQItem(
      id: 'process_2',
      keywords: ['thử', 'thử đồ', 'mặc thử'],
      question: 'Có được thử đồ trước không?',
      answer:
          'Có! Bạn có thể đến trực tiếp chi nhánh để thử đồ trước khi thuê. Mở app để xem chi nhánh gần bạn nhất.',
      category: 'process',
    ),
    FAQItem(
      id: 'process_3',
      keywords: ['giao hàng', 'ship', 'vận chuyển', 'đưa'],
      question: 'Có giao hàng tận nơi không?',
      answer:
          'Có! Chúng tôi hỗ trợ giao hàng tận nơi trong nội thành. Phí ship tùy khoảng cách, hoặc bạn có thể đến lấy trực tiếp.',
      category: 'process',
    ),

    // === CHI NHÁNH ===
    FAQItem(
      id: 'branch_1',
      keywords: ['chi nhánh', 'cửa hàng', 'địa chỉ', 'ở đâu'],
      question: 'Rentify có những chi nhánh nào?',
      answer:
          'Rentify có nhiều chi nhánh tại Hà Nội. Bạn mở tab "Chi nhánh" trong app để xem vị trí và tìm chi nhánh gần nhất.',
      category: 'branch',
    ),
    FAQItem(
      id: 'branch_2',
      keywords: ['giờ', 'mở cửa', 'đóng cửa', 'làm việc'],
      question: 'Giờ mở cửa của Rentify?',
      answer:
          'Thứ 2 - Thứ 7: 8:00 - 21:00. Chủ nhật: 9:00 - 18:00. Một số chi nhánh có thể khác, bạn kiểm tra trong app nhé.',
      category: 'branch',
    ),

    // === CHÍNH SÁCH ===
    FAQItem(
      id: 'policy_1',
      keywords: ['hủy', 'hủy đơn', 'hoàn tiền', 'cancel'],
      question: 'Chính sách hủy đơn như thế nào?',
      answer:
          'Hủy trước 24h: hoàn tiền 100%. Hủy trong 24h: hoàn 50%. Không hủy được sau khi đã nhận đồ.',
      category: 'policy',
    ),
    FAQItem(
      id: 'policy_2',
      keywords: ['trễ', 'muộn', 'quá hạn', 'trả trễ'],
      question: 'Nếu trả đồ trễ thì sao?',
      answer:
          'Trả trễ sẽ bị phạt 50% giá thuê cho mỗi ngày muộn. Vui lòng liên hệ sớm nếu cần gia hạn nhé.',
      category: 'policy',
    ),
    FAQItem(
      id: 'policy_3',
      keywords: ['hỏng', 'rách', 'bẩn', 'hư hỏng'],
      question: 'Nếu làm hỏng trang phục thì sao?',
      answer:
          'Hư hỏng nhỏ: trừ một phần tiền cọc. Hư hỏng nặng: có thể phải đền bù thêm. Hãy cẩn thận khi sử dụng nhé!',
      category: 'policy',
    ),

    // === TÀI KHOẢN ===
    FAQItem(
      id: 'account_1',
      keywords: ['đăng ký', 'tạo tài khoản', 'register'],
      question: 'Làm sao để đăng ký tài khoản?',
      answer:
          'Bạn có thể đăng ký bằng email hoặc đăng nhập nhanh bằng Google. Chỉ mất 30 giây!',
      category: 'account',
    ),
    FAQItem(
      id: 'account_2',
      keywords: ['quên mật khẩu', 'mật khẩu', 'password'],
      question: 'Tôi quên mật khẩu thì sao?',
      answer:
          'Nhấn "Quên mật khẩu" ở màn hình đăng nhập, nhập email và làm theo hướng dẫn để đặt lại mật khẩu.',
      category: 'account',
    ),

    // === SIZE ===
    FAQItem(
      id: 'size_1',
      keywords: ['size', 'kích thước', 'cỡ', 'số đo'],
      question: 'Làm sao để chọn size phù hợp?',
      answer:
          'Mỗi sản phẩm có bảng size chi tiết. Bạn cũng có thể đến cửa hàng thử trực tiếp để chọn size chuẩn nhất.',
      category: 'size',
    ),

    // === HỖ TRỢ ===
    FAQItem(
      id: 'support_1',
      keywords: ['liên hệ', 'hotline', 'hỗ trợ', 'contact'],
      question: 'Làm sao để liên hệ hỗ trợ?',
      answer:
          'Bạn có thể chat trực tiếp tại đây, gọi hotline 1900-xxxx, hoặc đến trực tiếp chi nhánh gần nhất.',
      category: 'support',
    ),
    FAQItem(
      id: 'support_2',
      keywords: ['khiếu nại', 'phản hồi', 'góp ý'],
      question: 'Tôi muốn góp ý/khiếu nại',
      answer:
          'Chúng tôi rất trân trọng ý kiến của bạn! Vui lòng gửi email về contact@rentify.vn hoặc gọi hotline nhé.',
      category: 'support',
    ),
  ];

  /// Tìm câu trả lời từ FAQ local
  FAQItem? findFAQAnswer(String userMessage) {
    final normalizedInput = _normalizeText(userMessage);

    // Tính điểm match cho mỗi FAQ
    FAQItem? bestMatch;
    int bestScore = 0;

    for (final faq in _faqDatabase) {
      int score = 0;
      for (final keyword in faq.keywords) {
        if (normalizedInput.contains(_normalizeText(keyword))) {
          score += 2; // Mỗi keyword match được 2 điểm
        }
      }

      // Bonus nếu match nhiều keywords
      if (score > bestScore) {
        bestScore = score;
        bestMatch = faq;
      }
    }

    // Chỉ trả về nếu đủ confident (ít nhất 2 điểm = 1 keyword match)
    if (bestScore >= 2) {
      return bestMatch;
    }

    return null;
  }

  /// Normalize text để so sánh
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
  }

  /// Gọi Gemini AI để trả lời
  Future<String> askGemini(String userMessage) async {
    if (_model == null) {
      _initGemini();
    }

    if (_chatSession == null) {
      return 'Xin lỗi, tính năng AI đang bảo trì. Bạn có thể hỏi các câu hỏi thường gặp hoặc liên hệ hotline nhé!';
    }

    try {
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );

      return response.text ?? 'Xin lỗi, mình chưa hiểu câu hỏi. Bạn có thể hỏi lại được không?';
    } catch (e) {
      return 'Xin lỗi, có lỗi xảy ra. Bạn thử hỏi lại hoặc liên hệ hotline nhé!';
    }
  }

  /// Phương thức chính: Trả lời câu hỏi (FAQ first, AI fallback)
  Future<String> getAnswer(String userMessage) async {
    // Bước 1: Tìm trong FAQ local
    final faqAnswer = findFAQAnswer(userMessage);
    if (faqAnswer != null) {
      return faqAnswer.answer;
    }

    // Bước 2: Không tìm thấy FAQ -> Gọi Gemini AI
    if (_apiKey != 'AIzaSyBS3NSD5fioGf61VSetC83vbBap_Fpm9P4') {
      return await askGemini(userMessage);
    }

    // Bước 3: Không có API key -> Trả lời mặc định
    return _getDefaultResponse();
  }

  /// Trả lời mặc định khi không match FAQ và không có AI
  String _getDefaultResponse() {
    return 'Cảm ơn bạn đã nhắn tin! Mình có thể giúp bạn về:\n'
        '• Giá thuê trang phục\n'
        '• Cách đặt thuê\n'
        '• Chi nhánh gần nhất\n'
        '• Chính sách thuê & trả\n\n'
        'Bạn muốn hỏi về vấn đề nào?';
  }

  /// Lấy danh sách gợi ý nhanh
  List<String> getQuickSuggestions() {
    return const [
      'Giá thuê bao nhiêu?',
      'Cách thuê như thế nào?',
      'Chi nhánh gần tôi',
      'Chính sách hoàn tiền',
      'Size của tôi là gì?',
    ];
  }

  /// Kiểm tra API key đã được cấu hình chưa
  bool get isAIEnabled => _apiKey != 'AIzaSyBS3NSD5fioGf61VSetC83vbBap_Fpm9P4';

  /// Reset chat session (bắt đầu cuộc trò chuyện mới)
  void resetChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }
}
