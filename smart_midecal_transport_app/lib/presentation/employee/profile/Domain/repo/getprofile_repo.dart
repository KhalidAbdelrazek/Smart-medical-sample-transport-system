import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/profile/Domain/Entity/getprofile_response.dart';
abstract class GetProfileRepo {
  Future<Either<Failures, getprofileDataEntity>> getProfile(
  );
}

    
