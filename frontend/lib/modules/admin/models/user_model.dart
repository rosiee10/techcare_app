/// User Model class following OOP principles
/// Represents a user entity with all necessary properties
class UserModel {
  final int id;
  final String username;
  final String firstname;
  final String lastname;
  final String? middlename;
  final String? extname;
  final String email;
  final String? contactNo;
  final String role;
  final String? deployment;
  final String? subRole;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.firstname,
    required this.lastname,
    this.middlename,
    this.extname,
    required this.email,
    this.contactNo,
    required this.role,
    this.deployment,
    this.subRole,
    required this.isActive,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  /// Get full name of the user
  String get fullName {
    final middle = middlename != null && middlename!.isNotEmpty ? ' ${middlename![0]}.' : '';
    final ext = extname != null && extname!.isNotEmpty ? ' $extname' : '';
    return '$firstname$middle $lastname$ext';
  }

  /// Get initials for avatar
  String get initials {
    return '${firstname[0]}${lastname[0]}'.toUpperCase();
  }

  /// Get role display name
  String get roleDisplay {
    switch (role) {
      case 'ADMIN':
        return 'Admin';
      case 'DOCTOR':
        return 'Doctor';
      case 'NURSE':
        // Show sub-role if available
        if (subRole == 'RN') return 'Registered Nurse';
        if (subRole == 'ATTENDANT') return 'Nursing Attendant';
        return 'Nurse';
      case 'OPD_CLERK':
        return 'OPD Clerk';
      case 'PHARMACY':
        return 'Pharmacy';
      case 'LABORATORY':
        return 'Laboratory';
      default:
        return role;
    }
  }

  /// Get status display text
  String get statusDisplay => isActive ? 'Active' : 'Inactive';

  /// Factory constructor to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] as int,
      username: json['username'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      middlename: json['middlename'] as String?,
      extname: json['extname'] as String?,
      email: json['email'] as String,
      contactNo: json['contact_number'] as String?,
      role: json['user_role'] as String,
      deployment: json['deployment'] as String?,
      subRole: json['sub_role'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstname': firstname,
      'lastname': lastname,
      'middlename': middlename,
      'extname': extname,
      'email': email,
      'contact_no': contactNo,
      'user_role': role,
      'deployment': deployment,
      'sub_role': subRole,
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    int? id,
    String? username,
    String? firstname,
    String? lastname,
    String? middlename,
    String? extname,
    String? email,
    String? contactNo,
    String? role,
    String? deployment,
    String? subRole,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      middlename: middlename ?? this.middlename,
      extname: extname ?? this.extname,
      email: email ?? this.email,
      contactNo: contactNo ?? this.contactNo,
      role: role ?? this.role,
      deployment: deployment ?? this.deployment,
      subRole: subRole ?? this.subRole,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, fullName: $fullName, role: $role, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
