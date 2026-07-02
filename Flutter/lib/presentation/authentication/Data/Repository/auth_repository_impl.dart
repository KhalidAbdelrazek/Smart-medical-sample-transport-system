import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Data/Data%20Sources/remote/auth_remote_ds.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_employee_rb.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_employee_response.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Repository/auth_repository.dart';

import 'package:smart_midecal_transport_app/presentation/authentication/Data/Models/login_admin_rb_dm.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Data/Models/login_employee_rb_dm.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_admin_rb.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_admin_response.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl extends AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;
  AuthRepositoryImpl({required this.authRemoteDataSource});

  @override
  Future<Either<Failures, LoginEmployeeResponseEntity>> loginEmployee(
    LoginEmployeeRequestBodyEntity loginEmployeeRequestBodyEntity,
  ) {
    return authRemoteDataSource.loginEmployee(
      LoginEmployeeRequestBodyDm(
        email: loginEmployeeRequestBodyEntity.email,
        password: loginEmployeeRequestBodyEntity.password,
      ),
    );
  }

  @override
  Future<Either<Failures, LoginAdminResponseEntity>> loginAdmin(
    LoginAdminRequestBodyEntity loginAdminRequestBodyEntity,
  ) {
    return authRemoteDataSource.loginAdmin(
      LoginAdminRequestBodyDm(
        email: loginAdminRequestBodyEntity.email,
        password: loginAdminRequestBodyEntity.password,
      ),
    );
  }
}
