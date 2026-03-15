class GetprofileResponse {
  bool? success;
  String? message;
  getprofileDataEntity? data;
  dynamic errors;
}

class getprofileDataEntity {
  String? name;
  String? email;
  String? id;
  String? role;

  getprofileDataEntity({this.name, this.email, this.id, this.role});

  factory getprofileDataEntity.fromJson(Map<String, dynamic> json) {
    return getprofileDataEntity(
      name: json['name'],
      email: json['email'],
      id : json['id'],
      role: json['role'],
    );
  }
}