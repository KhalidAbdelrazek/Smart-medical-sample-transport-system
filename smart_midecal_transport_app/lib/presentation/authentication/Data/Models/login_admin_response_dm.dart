import '../../Domain/Entity/login_admin_response.dart';
import '../../Domain/Entity/login_employee_response.dart';

class LoginAdminResponseDm extends LoginAdminResponseEntity {
  LoginAdminResponseDm({
    super.success,
    super.message,
    super.data,
    super.errors,
  });

  factory LoginAdminResponseDm.fromJson(Map<String, dynamic> json) {
    return LoginAdminResponseDm(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? LoginAdminDataDm.fromJson(json['data'])
          : null,
      errors: json['errors'],
    );
  }
}

class LoginAdminDataDm extends LoginAdminDataEntity {
  LoginAdminDataDm({super.refresh, super.access, super.user});

  factory LoginAdminDataDm.fromJson(Map<String, dynamic> json) {
    return LoginAdminDataDm(
      refresh: json['refresh'],
      access: json['access'],
      user: json['user'] != null ? UserEntity.fromJson(json['user']) : null,
    );
  }
}
