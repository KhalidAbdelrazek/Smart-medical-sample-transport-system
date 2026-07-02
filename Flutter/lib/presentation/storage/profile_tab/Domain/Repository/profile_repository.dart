import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Domain/Entity/get_profle_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failures, GetProfileEntity>> getProfile();
}
