import '../../Domain/Entity/login_employee_rb.dart';

class LoginEmployeeRequestBodyDm extends LoginEmployeeRequestBodyEntity {
  LoginEmployeeRequestBodyDm({required super.email, required super.password});
  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['email'] = email;
    map['password'] = password;
    return map;
  }
}
