// {
//     "success": true,
//     "message": "Login successful",
//     "data": {
//         "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc3MzA4OTgxNSwiaWF0IjoxNzcyNDg1MDE1LCJqdGkiOiJiZjJhZmQyMDQxZDU0Y2Y4OWMzM2I0OWNlN2U5YjgxYSIsInVzZXJfaWQiOiJkNWI4MWMxZS1iMTAyLTQxMTAtOTRmMC03ZWFkN2NlN2U3NzQifQ.D91kE3rNxJJBnmuRHjdDJt3MhWuHo7SQbbPTFYlq-uY",
//         "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzcyNTI4MjE1LCJpYXQiOjE3NzI0ODUwMTUsImp0aSI6IjViY2M0NWY1NTA3NzRhNTg5ZGJlZjU1OGQ5YjNiZGViIiwidXNlcl9pZCI6ImQ1YjgxYzFlLWIxMDItNDExMC05NGYwLTdlYWQ3Y2U3ZTc3NCJ9.5s7JDjxpDu4kcU1M_hfS_iQnt_WbqGULzDLp6x2hefQ",
//         "user": {
//             "id": "d5b81c1e-b102-4110-94f0-7ead7ce7e774",
//             "name": "Doctor One",
//             "email": "doctor1@bioroute.com",
//             "role": "DOCTOR",
//             "department": "Cardiology",
//             "shift": "",
//             "employee_id": "EMP-DR-001"
//         }
//     },
//     "errors": null
// }

class LoginEmployeeResponseEntity {
  bool? success;
  String? message;
  String? refresh;
  String? access;
  UserEntity? user;
  dynamic errors;
  LoginEmployeeResponseEntity({
    this.success,
    this.message,
    this.refresh,
    this.access,
    this.user,
    this.errors,
  });

  // from json to object
  factory LoginEmployeeResponseEntity.fromJson(Map<String, dynamic> json) {
    return LoginEmployeeResponseEntity(
      refresh: json['refresh'],
      access: json['access'],
      user: UserEntity.fromJson(json['user']),
    );
  }
}

class UserEntity {
  String? id;
  String? name;
  String? email;
  String? role;
  String? department;
  String? shift;
  String? employeeId;
  UserEntity({
    this.id,
    this.name,
    this.email,
    this.role,
    this.department,
    this.shift,
    this.employeeId,
  });
  // from json to object
  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
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
