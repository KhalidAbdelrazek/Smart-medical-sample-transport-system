import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Domain/Repository/profile_repository.dart';

@Injectable(as: ProfileRepository)
class AuthRepositoryImpl extends ProfileRepository {
  // final AuthRemoteDataSource authRemoteDataSource;
  // AuthRepositoryImpl({required this.authRemoteDataSource});

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
