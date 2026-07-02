import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Data/Models/login_admin_rb_dm.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Data/Models/login_admin_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Data/Models/login_employee_rb_dm.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Data/Models/login_employee_response_dm.dart';

abstract class AuthRemoteDataSource {
  Future<Either<Failures, LoginEmployeeResponseDm>> loginEmployee(
    LoginEmployeeRequestBodyDm loginEmployeeRequestBodyDm,
  );
  Future<Either<Failures, LoginAdminResponseDm>> loginAdmin(
    LoginAdminRequestBodyDm loginAdminRequestBodyDm,
  );
}
