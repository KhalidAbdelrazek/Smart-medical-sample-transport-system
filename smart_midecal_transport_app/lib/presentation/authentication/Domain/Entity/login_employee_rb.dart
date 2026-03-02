class LoginEmployeeRequestBodyEntity {
    String email;
    String password;
    LoginEmployeeRequestBodyEntity({required this.email, required this.password});
    Map<String, dynamic> toJson() {
        final map = <String, dynamic>{};
        map['email'] = email;
        map['password'] = password;
        return map;
    }
}