import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Data/Data%20Sources/remote/profile_ds.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Domain/Entity/get_profle_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Domain/Repository/profile_repository.dart';

@Injectable(as: ProfileRepository)
class ProfileRepositoryImpl extends ProfileRepository {
  ProfileDataSource profileDataSource;
  ProfileRepositoryImpl({required this.profileDataSource});
  
  @override
  Future<Either<Failures, GetProfileEntity>> getProfile() {
    // TODO: implement getProfile
    throw UnimplementedError();
  }

  // @override
  // Future<Either<Failures, LoginEmployeeResponseEntity>> loginEmployee(
  //   LoginEmployeeRequestBodyEntity loginEmployeeRequestBodyEntity,
  // ) {
  //   return authRemoteDataSource.loginEmployee(
  //     LoginEmployeeRequestBodyDm(
  //       email: loginEmployeeRequestBodyEntity.email,
  //       password: loginEmployeeRequestBodyEntity.password,
  //     ),
  //   );
  // }

  // @override
  // Future<Either<Failures, LoginAdminResponseEntity>> loginAdmin(
  //   LoginAdminRequestBodyEntity loginAdminRequestBodyEntity,
  // ) {
  //   return authRemoteDataSource.loginAdmin(
  //     LoginAdminRequestBodyDm(
  //       email: loginAdminRequestBodyEntity.email,
  //       password: loginAdminRequestBodyEntity.password,
  //     ),
  //   );
  // }
}
