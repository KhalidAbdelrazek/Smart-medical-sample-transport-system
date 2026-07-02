import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Data/Models/get_profle_dm.dart';

abstract class ProfileDataSource {
  Future<Either<Failures, GetProfileDm>> getProfile();
}
