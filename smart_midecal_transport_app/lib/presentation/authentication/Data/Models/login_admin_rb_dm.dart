import '../../Domain/Entity/login_admin_rb.dart';

class LoginAdminRequestBodyDm extends LoginAdminRequestBodyEntity {
  LoginAdminRequestBodyDm({required super.email, required super.password});

  @override
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = email; // Map entity email field to id key in JSON
    map['password'] = password;
    return map;
  }
}
