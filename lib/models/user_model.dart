class UserModel {
  final String id;
  final String accsoftId;
  final String name;
  final String role; // 'student' or 'admin'

  UserModel({
    required this.id,
    required this.accsoftId,
    required this.name,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      accsoftId: json['accsoftId'],
      name: json['name'],
      role: json['role'] ?? 'student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accsoftId': accsoftId,
      'name': name,
      'role': role,
    };
  }
}
