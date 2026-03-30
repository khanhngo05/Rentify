import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho người dùng
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? address;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.phoneNumber,
    this.avatarUrl,
    this.address,
    this.role = 'user',
    required this.createdAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'],
      avatarUrl: data['avatarUrl'],
      address: data['address'],
      role: data['role'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'address': address,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isAdmin => role == 'admin';
}
