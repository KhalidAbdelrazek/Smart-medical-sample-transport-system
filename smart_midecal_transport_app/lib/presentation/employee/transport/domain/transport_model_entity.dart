class TransportModelEntity {
  final String id;
  final String status;
  final String code;
  final String pickup;
  final String dropoff;
  final String person;
  final String time;

  TransportModelEntity({
    required this.id,
    required this.status,
    required this.code,
    required this.pickup,
    required this.dropoff,
    required this.person,
    required this.time,
  });

  factory TransportModelEntity.fromJson(Map<String, dynamic> json) {
    return TransportModelEntity(
      id: json["id"],
      status: json["status"],
      code: json["code"],
      pickup: json["pickup"],
      dropoff: json["dropoff"],
      person: json["person"],
      time: json["time"],
    );
  }
}
