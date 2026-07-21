class User {
  final String userId;
  final String displayName;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? phone;
  final String email;
  final String userType; // 'student' or 'professor'
  final DateTime? createdAt;
  final bool isBanned;

  User({
    required this.userId,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.phone,
    required this.email,
    required this.userType,
    this.createdAt,
    this.isBanned = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      displayName: json['display_name'] ?? json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      middleName: json['middle_name'],
      phone: json['phone'],
      email: json['email'] ?? '',
      userType: json['user_type'] ?? json['role'] ?? json['account_type'] ?? 'student',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      isBanned: json['is_banned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'phone': phone,
      'email': email,
      'user_type': userType,
      'created_at': createdAt?.toIso8601String(),
      'is_banned': isBanned,
    };
  }

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  User copyWith({
    String? userId,
    String? displayName,
    String? firstName,
    String? lastName,
    String? middleName,
    String? phone,
    String? email,
    String? userType,
    DateTime? createdAt,
    bool? isBanned,
  }) {
    return User(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      isBanned: isBanned ?? this.isBanned,
    );
  }
}
