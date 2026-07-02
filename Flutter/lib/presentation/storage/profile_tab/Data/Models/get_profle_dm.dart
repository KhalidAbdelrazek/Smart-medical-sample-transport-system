import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Domain/Entity/get_profle_entity.dart';

class GetProfileDm extends GetProfileEntity {
  GetProfileDm({
    required super.success,
    required super.message,
    super.data,
    super.errors,
  });

  factory GetProfileDm.fromJson(Map<String, dynamic> json) {
    return GetProfileDm(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? ProfileDataDm.fromJson(json['data']) : null,
      errors: json['errors'] != null
          ? ApiErrorDm.fromJson(json['errors'])
          : null,
    );
  }
}

// Data Model for the 'data' object
class ProfileDataDm extends ProfileDataEntity {
  ProfileDataDm({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.department,
    required super.shift,
    required super.employeeId,
  });

  factory ProfileDataDm.fromJson(Map<String, dynamic> json) {
    return ProfileDataDm(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      department: json['department'] ?? '',
      shift: json['shift'] ?? '',
      employeeId: json['employee_id'] ?? '',
    );
  }
}

// Data Model for the 'errors' object
class ApiErrorDm extends ApiErrorEntity {
  ApiErrorDm({super.detail, super.code, super.messages});

  factory ApiErrorDm.fromJson(Map<String, dynamic> json) {
    return ApiErrorDm(
      detail: json['detail'],
      code: json['code'],
      messages: json['messages'] != null
          ? List<Map<String, dynamic>>.from(json['messages'])
          : null,
    );
  }
}
