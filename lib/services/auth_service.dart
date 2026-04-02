import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/app_constants.dart';
import '../models/user_model.dart';

/// Service xu ly dang nhap, dang ky, dang xuat.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// User hien tai (null neu chua dang nhap).
  User? get currentUser => _auth.currentUser;

  /// Kiem tra da dang nhap chua.
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream theo doi trang thai dang nhap.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Dang ky tai khoan moi bang email/password.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(displayName);

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Khong tao duoc tai khoan nguoi dung.',
      );
    }

    return _upsertUserFromFirebaseUser(
      firebaseUser,
      fallbackEmail: email,
      fallbackDisplayName: displayName,
      fallbackPhoneNumber: phoneNumber,
    );
  }

  /// Dang nhap bang email + mat khau.
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) return null;

    return _upsertUserFromFirebaseUser(firebaseUser, fallbackEmail: email);
  }

  /// Dang nhap bang Google.
  Future<UserModel> signInWithGoogle() async {
    UserCredential credential;
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters(<String, String>{'prompt': 'select_account'});
        credential = await _auth.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn(scopes: <String>['email', 'profile']);
        await googleSignIn.signOut();
        final googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          throw FirebaseAuthException(
            code: 'sign_in_canceled',
            message: 'Nguoi dung da huy dang nhap Google.',
          );
        }

        final googleAuth = await googleUser.authentication;
        if (googleAuth.idToken == null && googleAuth.accessToken == null) {
          throw FirebaseAuthException(
            code: 'missing-auth-token',
            message: 'Khong lay duoc token tu Google Sign-In.',
          );
        }

        final authCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        credential = await _auth.signInWithCredential(authCredential);
      }
    } on UnimplementedError {
      throw FirebaseAuthException(
        code: 'operation-not-supported',
        message: 'Google sign-in chua duoc ho tro tren nen tang nay.',
      );
    }

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Dang nhap Google khong thanh cong.',
      );
    }

    return _upsertUserFromFirebaseUser(firebaseUser);
  }

  /// Dang xuat.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Lay thong tin UserModel cua user dang dang nhap.
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    final cached = await _getUserFromFirestore(user.uid);
    if (cached != null) return cached;

    return _upsertUserFromFirebaseUser(user);
  }

  /// Doi mat khau.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null || user.email == null) return;

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  /// Gui email dat lai mat khau.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Cap nhat thong tin profile cua user.
  Future<void> updateUserProfile({
    String? phoneNumber,
    String? avatarUrl,
    String? address,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final userRef = _db.collection(AppConstants.usersCollection).doc(user.uid);

    final updates = <String, dynamic>{};
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (address != null) updates['address'] = address;

    await userRef.update(updates);
  }

  /// Lay UserModel tu Firestore.
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    return UserModel.fromFirestore(data, doc.id);
  }

  /// Tao user doc neu chua ton tai, hoac lay doc hien tai.
  Future<UserModel> _upsertUserFromFirebaseUser(
    User firebaseUser, {
    String? fallbackEmail,
    String? fallbackDisplayName,
    String? fallbackPhoneNumber,
  }) async {
    final userRef = _db
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid);
    final existing = await userRef.get();

    if (existing.exists && existing.data() != null) {
      return UserModel.fromFirestore(existing.data()!, existing.id);
    }

    final email = (firebaseUser.email ?? fallbackEmail ?? '').trim();
    final rawDisplayName = firebaseUser.displayName?.trim() ?? '';
    final fallbackName = fallbackDisplayName?.trim() ?? '';
    final displayName = rawDisplayName.isNotEmpty
        ? rawDisplayName
        : fallbackName.isNotEmpty
        ? fallbackName
        : _nameFromEmail(email);

    final user = UserModel(
      uid: firebaseUser.uid,
      email: email,
      displayName: displayName,
      phoneNumber: firebaseUser.phoneNumber ?? fallbackPhoneNumber,
      avatarUrl: firebaseUser.photoURL,
      role: AppConstants.roleUser,
      createdAt: DateTime.now(),
    );

    await userRef.set(user.toMap(), SetOptions(merge: true));
    return user;
  }

  String _nameFromEmail(String email) {
    if (email.contains('@')) {
      final name = email.split('@').first.trim();
      if (name.isNotEmpty) return name;
    }
    return 'rentify_user';
  }
}
