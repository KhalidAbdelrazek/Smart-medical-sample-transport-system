import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';

class RestrictionsDm extends RestrictionsEntity {
  RestrictionsDm({super.success, super.message, super.data, super.errors});
}

class DoctorsOrStorageRestrictionsDm
    extends DoctorsOrStorageRestrictionsEntity {
  DoctorsOrStorageRestrictionsDm({
    super.storageSamples,
    super.doctorSamples,
    super.transportCar,
  });
}

class StorageSamplesDm extends StorageSamplesEntity {
  StorageSamplesDm({super.id, super.name, super.isRestricted});
}

class DoctorsSamplesDm extends DoctorsSamplesEntity {
  DoctorsSamplesDm({super.id, super.name, super.isRestricted});
}

class TransportCarDm extends TransportCarEntity {
  TransportCarDm({super.mode, super.isRestricted});
}
