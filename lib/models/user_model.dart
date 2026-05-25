class UserModel {
  final String id;
  final String accsoftId;
  final String name;
  final String role; // 'student' or 'admin'
  final String? course;
  final bool feePaid;
  final double feeAmount;
  final bool hasAttempted;

  final bool isSuperAdmin;
  final bool forcePasswordChange;

  UserModel({
    required this.id,
    required this.accsoftId,
    required this.name,
    required this.role, // 'student' or 'admin'
    this.course,
    this.feePaid = false,
    this.feeAmount = 1100.0,
    this.hasAttempted = false,
    this.isSuperAdmin = false,
    this.forcePasswordChange = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      accsoftId: json['accsoftId'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'student',
      course: json['course'],
      feePaid: json['feePaid'] ?? false,
      feeAmount: (json['feeAmount'] ?? 1100.0).toDouble(),
      hasAttempted: json['hasAttempted'] ?? false,
      isSuperAdmin: json['isSuperAdmin'] ?? false,
      forcePasswordChange: json['forcePasswordChange'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accsoftId': accsoftId,
      'name': name,
      'role': role,
      'course': course,
      'feePaid': feePaid,
      'feeAmount': feeAmount,
      'hasAttempted': hasAttempted,
      'isSuperAdmin': isSuperAdmin,
      'forcePasswordChange': forcePasswordChange,
    };
  }

  UserModel copyWith({
    String? id,
    String? accsoftId,
    String? name,
    String? role,
    String? course,
    bool? feePaid,
    double? feeAmount,
    bool? hasAttempted,
    bool? isSuperAdmin,
    bool? forcePasswordChange,
  }) {
    return UserModel(
      id: id ?? this.id,
      accsoftId: accsoftId ?? this.accsoftId,
      name: name ?? this.name,
      role: role ?? this.role,
      course: course ?? this.course,
      feePaid: feePaid ?? this.feePaid,
      feeAmount: feeAmount ?? this.feeAmount,
      hasAttempted: hasAttempted ?? this.hasAttempted,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      forcePasswordChange: forcePasswordChange ?? this.forcePasswordChange,
    );
  }

  String get feeStatusText => feePaid
      ? 'Paid — Rs.${feeAmount.toStringAsFixed(0)} confirmed'
      : 'Not paid — Rs.${feeAmount.toStringAsFixed(0)} pending';

  String get attemptStatusText => hasAttempted
      ? 'Already attempted — not eligible'
      : 'None — eligible to attempt';
}
