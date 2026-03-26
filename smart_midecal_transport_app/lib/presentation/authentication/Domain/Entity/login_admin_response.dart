import 'login_employee_response.dart';

class LoginAdminResponseEntity {
  bool? success;
  String? message;
  LoginAdminDataEntity? data;
  dynamic errors;

  LoginAdminResponseEntity({
    this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory LoginAdminResponseEntity.fromJson(Map<String, dynamic> json) {
    return LoginAdminResponseEntity(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? LoginAdminDataEntity.fromJson(json['data'])
          : null,
      errors: json['errors'],
    );
  }
}

class LoginAdminDataEntity {
  String? refresh;
  String? access;
  UserEntity? user;

  LoginAdminDataEntity({this.refresh, this.access, this.user});

  factory LoginAdminDataEntity.fromJson(Map<String, dynamic> json) {
    return LoginAdminDataEntity(
      refresh: json['refresh'],
      access: json['access'],
      user: json['user'] != null ? UserEntity.fromJson(json['user']) : null,
    );
  }
}
