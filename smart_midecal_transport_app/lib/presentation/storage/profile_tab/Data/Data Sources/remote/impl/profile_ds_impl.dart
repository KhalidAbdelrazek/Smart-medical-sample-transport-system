import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Data/Data Sources/remote/profile_ds.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Data/Models/get_profle_dm.dart';

@Injectable(as: ProfileDataSource)
class ProfileDataSourceImpl implements ProfileDataSource {
  ApiManager apiManager;
  ProfileDataSourceImpl({required this.apiManager});  

  @override
  Future<Either<Failures, GetProfileDm>> getProfile() {
    // TODO: implement getProfile
    throw UnimplementedError();
  }
}
