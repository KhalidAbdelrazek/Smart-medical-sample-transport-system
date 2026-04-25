import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/domain/entities/admin_stats_entity.dart';

class AdminStatsModel extends AdminStatsEntity {
  AdminStatsModel({super.success, super.message, super.data, super.errors});

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? DataStatsModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'errors': errors,
      };
}

class DataStatsModel extends DataStatsEntity {
  DataStatsModel({super.period, super.role, super.doctors, super.storage});

  factory DataStatsModel.fromJson(Map<String, dynamic> json) {
    return DataStatsModel(
      period: json['period'] as String?,
      role: json['role'] as String?,
      doctors: json['doctors'] != null
          ? DoctorStatsModel.fromJson(json['doctors'] as Map<String, dynamic>)
          : null,
      storage: json['storage'] != null
          ? StorageStatsModel.fromJson(json['storage'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DoctorStatsModel extends DoctorStatsEntity {
  DoctorStatsModel({
    super.totalRequests,
    super.successful,
    super.failed,
    super.cancelled,
    super.pending,
  });

  factory DoctorStatsModel.fromJson(Map<String, dynamic> json) {
    return DoctorStatsModel(
      totalRequests: json['total_requests'] as int?,
      successful: json['successful'] as int?,
      failed: json['failed'] as int?,
      cancelled: json['cancelled'] as int?,
      pending: json['pending'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_requests': totalRequests,
        'successful': successful,
        'failed': failed,
        'cancelled': cancelled,
        'pending': pending,
      };
}

class StorageStatsModel extends StorageStatsEntity {
  StorageStatsModel({
    super.totalActions,
    super.carDispatch,
    super.sampleAddedToCar,
    super.sampleRemovedFromCar,
    super.transportRequestUpdate,
    super.other,
  });

  factory StorageStatsModel.fromJson(Map<String, dynamic> json) {
    return StorageStatsModel(
      totalActions: json['total_actions'] as int?,
      carDispatch: json['car_dispatch'] as int?,
      // Real API keys: sample_added, sample_removed, transport_updates
      sampleAddedToCar: json['sample_added'] as int?,
      sampleRemovedFromCar: json['sample_removed'] as int?,
      transportRequestUpdate: json['transport_updates'] as int?,
      other: json['other'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_actions': totalActions,
        'car_dispatch': carDispatch,
        'sample_added': sampleAddedToCar,
        'sample_removed': sampleRemovedFromCar,
        'transport_updates': transportRequestUpdate,
        'other': other,
      };
}
