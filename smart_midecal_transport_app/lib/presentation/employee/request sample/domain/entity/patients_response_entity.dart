class PatientResponseEntity {
  final List<PatientEntity> data;
  final int page;
  final int total;

  PatientResponseEntity({
    required this.data,
    required this.page,
    required this.total,
  });

  factory PatientResponseEntity.fromJson(Map<String, dynamic> json) {
    return PatientResponseEntity(
      data: (json["data"] as List)
          .map((e) => PatientEntity.fromJson(e))
          .toList(),
      page: json["page"],
      total: json["total"],
    );
  }
}

class PatientEntity {
  final int id;
  final String name;

  PatientEntity({required this.id, required this.name});

  factory PatientEntity.fromJson(Map<String, dynamic> json) {
    return PatientEntity(
      id: json["id"],
      name: json["name"],
    );
  }
}
