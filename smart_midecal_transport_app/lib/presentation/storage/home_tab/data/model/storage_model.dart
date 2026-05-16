import 'package:smart_midecal_transport_app/presentation/storage/home_tab/domain/entities/static_storage_entity.dart';

class StorageStatisticsModel extends StorageStatisticsEntity {
  StorageStatisticsModel({
    required super.totalactions,
    required super.cardispatch,
    required super.sampleaddedtocar,
    required super.sampleremovedfromcar,
    required super.transportrequestupdate,
    required super.other,
    required super.period,
    required super.role,
  });

  factory StorageStatisticsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    return StorageStatisticsModel(
      totalactions: data['total_actions'],
      cardispatch: data['car_dispatch'],
      sampleaddedtocar: data['sample_added_to_car'],
      sampleremovedfromcar: data['sample_removed_from_car'],
      transportrequestupdate: data['transport_request_update'],
      other: (data['other'] as num).toDouble(),
      period: data['period'],
      role: data['role'],
    );
  }
}
