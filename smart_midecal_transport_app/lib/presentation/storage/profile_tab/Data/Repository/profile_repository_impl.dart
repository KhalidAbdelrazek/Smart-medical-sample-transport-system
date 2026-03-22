import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Data/Data%20Sources/profile_ds.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Domain/Entity/get_profle_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Domain/Repository/profile_repository.dart';

@Injectable(as: ProfileRepository)
class ProfileRepositoryImpl extends ProfileRepository {
  ProfileDataSource profileDataSource;
  ProfileRepositoryImpl({required this.profileDataSource});
  
  @override
  Future<Either<Failures, GetProfileEntity>> getProfile() {
    return profileDataSource.getProfile();
  }
}
