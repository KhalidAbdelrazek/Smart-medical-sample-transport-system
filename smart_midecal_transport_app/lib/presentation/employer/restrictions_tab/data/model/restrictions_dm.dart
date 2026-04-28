import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';

class PersonModel extends PersonEntity {
  PersonModel({
    super.id,
    super.name,
    super.email,
    super.isRestricted,
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as String?,
      name: (json['name'] ?? json['full_name'] ?? json['username']) as String?,
      email: json['email'] as String?,
      isRestricted: json['is_restricted'] ?? false,
    );
  }

  static List<PersonModel> fromJsonList(dynamic json) {
    if (json is List) {
      return json.map((e) => PersonModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
