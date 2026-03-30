import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

/// Service xử lý đăng nhập, đăng ký, đăng xuất
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// User hiện tại (null nếu chưa đăng nhập)
  User? get currentUser => _auth.currentUser;

  /// Kiểm tra đã đăng nhập chưa
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream theo dõi trạng thái đăng nhập (dùng cho StreamBuilder)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Đăng ký tài khoản mới
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    // Tạo tài khoản trên Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Cập nhật tên hiển thị
    await credential.user?.updateDisplayName(displayName);

    // Tạo document user trên Firestore
    final user = UserModel(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      phoneNumber: phoneNumber,
      role: AppConstants.roleUser,
      createdAt: DateTime.now(),
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toMap());

    return user;
  }

  /// Đăng nhập bằng email + mật khẩu
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Lấy thông tin user từ Firestore
    if (credential.user != null) {
      return await _getUserFromFirestore(credential.user!.uid);
    }
    return null;
  }

  /// Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Lấy thông tin UserModel của user đang đăng nhập
  Future<UserModel?> getCurrentUserModel() async {
    if (currentUser == null) return null;
    return await _getUserFromFirestore(currentUser!.uid);
  }

  /// Đổi mật khẩu
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null || user.email == null) return;

    // Xác thực lại trước khi đổi mật khẩu
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Lấy UserModel từ Firestore
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, doc.id);
  }
}
