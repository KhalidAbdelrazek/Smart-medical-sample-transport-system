import '../../Domain/Entity/login_employee_response.dart';

class LoginEmployeeResponseDm extends LoginEmployeeResponseEntity {
  LoginEmployeeResponseDm({
    super.success,
    super.message,
    super.refresh,
    super.access,
    super.user,
  });

  // from json to object
  factory LoginEmployeeResponseDm.fromJson(Map<String, dynamic> json) {
    return LoginEmployeeResponseDm(
      success: json['success'],
      message: json['message'],
      refresh: json['data'] != null ? json['data']['refresh'] : null,
      access: json['data'] != null ? json['data']['access'] : null,
      user: (json['data'] != null && json['data']['user'] != null)
          ? UserEntity.fromJson(json['data']['user'])
          : null,
    );
  }
}

class UserDm extends UserEntity {
  UserDm({
    super.id,
    super.name,
    super.email,
    super.role,
    super.department,
    super.shift,
    super.employeeId,
  });
  // from json to object
  factory UserDm.fromJson(Map<String, dynamic> json) {
    return UserDm(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      department: json['department'],
      shift: json['shift'],
      employeeId: json['employee_id'],
    );
  }
}
