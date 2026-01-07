class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin', 'employee'
  final bool isActive;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.isActive = true,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'employee',
      isActive: map['isActive'] ?? true,
      lastLogin: map['lastLogin'] != null ? DateTime.tryParse(map['lastLogin']) : null,
    );
  }
}
