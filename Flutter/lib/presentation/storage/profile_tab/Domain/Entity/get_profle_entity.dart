class GetProfileEntity {
  final bool success;
  final String message;
  final ProfileDataEntity? data;
  final ApiErrorEntity? errors;

  GetProfileEntity({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });
}

class ProfileDataEntity {
  final String id, name, email, role, department, shift, employeeId;
  ProfileDataEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.shift,
    required this.employeeId,
  });
}

class ApiErrorEntity {
  final String? detail;
  final String? code;
  final List<Map<String, dynamic>>? messages;
  ApiErrorEntity({this.detail, this.code, this.messages});
}
