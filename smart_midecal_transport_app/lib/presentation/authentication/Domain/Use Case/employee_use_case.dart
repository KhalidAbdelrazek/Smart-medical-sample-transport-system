import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_employee_rb.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_employee_response.dart';
import '../Repository/auth_repository.dart';

@injectable
class EmployeeUseCase {
  final AuthRepository authRepository;
  EmployeeUseCase({required this.authRepository});
  Future<Either<Failures, LoginEmployeeResponseEntity>> loginEmployee(
    LoginEmployeeRequestBodyEntity loginEmployeeRequestBodyEntity,
  ) {
    return authRepository.loginEmployee(loginEmployeeRequestBodyEntity);
  }
}
