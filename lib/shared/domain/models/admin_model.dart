import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AdminModel extends Equatable {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final DateTime createdAt;
  final String? profileImageUrl;
  final String role;
  final bool visible;

  const AdminModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.createdAt,
    this.profileImageUrl,
    this.role = 'admin',
    this.visible = true,
  });

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    // Support both old format (id, fullName, phoneNumber) and new format (uid, name, phone)
    final id = map['uid'] as String? ?? map['id'] as String;
    final name = map['name'] as String? ?? map['fullName'] as String;
    final phone = map['phone'] as String? ?? map['phoneNumber'] as String;
    final role = map['role'] as String? ?? 'admin';
    final visible = map['visible'] as bool? ?? true; // Default to true if not set
    
    return AdminModel(
      id: id,
      fullName: name,
      phoneNumber: phone,
      email: map['email'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      profileImageUrl: map['profileImageUrl'] as String?,
      role: role,
      visible: visible,
    );
  }

  Map<String, dynamic> toMap() {
    // Use the new format for Firestore: uid, name, phone, role, visible
    return {
      'uid': id,
      'name': fullName,
      'phone': phoneNumber,
      'email': email,
      'role': role,
      'visible': visible,
      'createdAt': Timestamp.fromDate(createdAt),
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      // Keep backward compatibility fields
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    };
  }

  AdminModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    DateTime? createdAt,
    String? profileImageUrl,
    String? role,
    bool? visible,
  }) {
    return AdminModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      visible: visible ?? this.visible,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        phoneNumber,
        email,
        createdAt,
        profileImageUrl,
        role,
        visible,
      ];
}

