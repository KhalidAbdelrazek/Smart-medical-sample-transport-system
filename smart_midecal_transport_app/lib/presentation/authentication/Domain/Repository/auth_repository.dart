import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_admin_rb.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_admin_response.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_employee_rb.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_employee_response.dart';

abstract class AuthRepository {
  Future<Either<Failures, LoginEmployeeResponseEntity>> loginEmployee(
    LoginEmployeeRequestBodyEntity loginEmployeeRequestBodyEntity,
  );
  Future<Either<Failures, LoginAdminResponseEntity>> loginAdmin(
    LoginAdminRequestBodyEntity loginAdminRequestBodyEntity,
  );
}
