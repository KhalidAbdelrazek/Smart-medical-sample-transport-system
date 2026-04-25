class AdminStatsEntity {
  final bool? success;
  final String? message;
  final DataStatsEntity? data;
  final dynamic errors;

  AdminStatsEntity({this.success, this.message, this.data, this.errors});
}

class DataStatsEntity {
  final String? period;
  final String? role;
  final DoctorStatsEntity? doctors;
  final StorageStatsEntity? storage;

  DataStatsEntity({this.period, this.role, this.doctors, this.storage});
}

class DoctorStatsEntity {
  final int? totalRequests;
  final int? successful;
  final int? failed;
  final int? cancelled;  
  final int? pending;

  DoctorStatsEntity({this.totalRequests, this.successful, this.failed, this.cancelled, this.pending});
}

class StorageStatsEntity {
  final int? totalActions;
  final int? carDispatch;
  final int? sampleAddedToCar;
  final int? sampleRemovedFromCar;
  final int? transportRequestUpdate;
  final int? other;

  StorageStatsEntity({this.totalActions, this.carDispatch, this.sampleAddedToCar, this.sampleRemovedFromCar, this.transportRequestUpdate, this.other});
}


