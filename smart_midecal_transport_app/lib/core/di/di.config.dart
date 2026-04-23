// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../presentation/authentication/Data/Data%20Sources/remote/auth_remote_ds.dart'
    as _i727;
import '../../presentation/authentication/Data/Data%20Sources/remote/impl/auth_remote_ds_impl.dart'
    as _i1029;
import '../../presentation/authentication/Data/Repository/auth_repository_impl.dart'
    as _i659;
import '../../presentation/authentication/Domain/Repository/auth_repository.dart'
    as _i471;
import '../../presentation/authentication/ui/cubit/admin_login_view_model.dart'
    as _i964;
import '../../presentation/authentication/ui/cubit/employee_login_view_model.dart'
    as _i600;
import '../../presentation/employee/home/data/data_source/impl/static_remote_ds_impl.dart'
    as _i265;
import '../../presentation/employee/home/data/data_source/static_remote_ds.dart'
    as _i966;
import '../../presentation/employee/home/data/repos/static_repo.dart' as _i927;
import '../../presentation/employee/home/domain/repos/static_repo.dart'
    as _i825;
import '../../presentation/employee/home/ui/cubit/employee_home_cubit.dart'
    as _i724;
import '../../presentation/employee/my_requests/cubit/my_requests_cubit.dart'
    as _i692;
import '../../presentation/employee/my_requests/data/data%20source/myrequest_data_source.dart'
    as _i274;
import '../../presentation/employee/my_requests/data/data%20source/myrequest_data_source_impl.dart'
    as _i1059;
import '../../presentation/employee/my_requests/data/repos/myrequest_repo_impl.dart'
    as _i1070;
import '../../presentation/employee/my_requests/domain/repos/my_request_repo.dart'
    as _i981;
import '../../presentation/employee/requests/Data/data%20source/requests_data_source.dart'
    as _i588;
import '../../presentation/employee/requests/Data/data%20source/requests_data_source_impl.dart'
    as _i128;
import '../../presentation/employee/requests/Data/repository/requests_repository_impl.dart'
    as _i1020;
import '../../presentation/employee/requests/domain/repository/requests_repository.dart'
    as _i960;
import '../../presentation/employee/requests/ui/cubit/blood_sample_cubit.dart'
    as _i497;
import '../../presentation/employer/restrictions_tab/cubit/restrictions_cubit.dart'
    as _i963;
import '../../presentation/employer/statistics_tab/cubit/statistics_cubit.dart'
    as _i327;
import '../../presentation/storage/home_tab/ui/cubit/home_cubit.dart' as _i385;
import '../../presentation/storage/profile_tab/Data/Data%20Sources/impl/profile_ds_impl.dart'
    as _i892;
import '../../presentation/storage/profile_tab/Data/Data%20Sources/profile_ds.dart'
    as _i582;
import '../../presentation/storage/profile_tab/Data/Repository/profile_repository_impl.dart'
    as _i597;
import '../../presentation/storage/profile_tab/Domain/Repository/profile_repository.dart'
    as _i247;
import '../../presentation/storage/profile_tab/ui/cubit/profile_cubit.dart'
    as _i50;
import '../../presentation/storage/requests_tab/data/data%20source/requests_data_source.dart'
    as _i212;
import '../../presentation/storage/requests_tab/data/data%20source/requests_data_source_impl.dart'
    as _i542;
import '../../presentation/storage/requests_tab/data/repository/requests_repository_impl.dart'
    as _i908;
import '../../presentation/storage/requests_tab/domain/repository/requests_repository.dart'
    as _i459;
import '../../presentation/storage/requests_tab/ui/cubit/blood_samples_cubit.dart'
    as _i6;
import '../api%20manager/api_manager.dart' as _i949;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i963.RestrictionsCubit>(() => _i963.RestrictionsCubit());
    gh.factory<_i327.StatisticsCubit>(() => _i327.StatisticsCubit());
    gh.factory<_i385.HomeCubit>(() => _i385.HomeCubit());
    gh.singleton<_i949.ApiManager>(() => _i949.ApiManager());
    gh.factory<_i274.MyRequestsDataSource>(
      () => _i1059.MyRequestsDataSourceImpl(apiManager: gh<_i949.ApiManager>()),
    );
    gh.factory<_i727.AuthRemoteDataSource>(
      () => _i1029.AuthRemoteDataSourceImpl(apiManager: gh<_i949.ApiManager>()),
    );
    gh.factory<_i582.ProfileDataSource>(
      () => _i892.ProfileDataSourceImpl(apiManager: gh<_i949.ApiManager>()),
    );
    gh.factory<_i212.RequestsDataSource>(
      () => _i542.RequestsDataSourceImpl(apiManager: gh<_i949.ApiManager>()),
    );
    gh.factory<_i459.RequestsRepository>(
      () => _i908.RequestsRepositoryImpl(
        requestsDataSource: gh<_i212.RequestsDataSource>(),
      ),
    );
    gh.factory<_i471.AuthRepository>(
      () => _i659.AuthRepositoryImpl(
        authRemoteDataSource: gh<_i727.AuthRemoteDataSource>(),
      ),
    );
    gh.factory<_i588.RequestsDataSource>(
      () => _i128.RequestsDataSourceImpl(apiManager: gh<_i949.ApiManager>()),
    );
    gh.factory<_i247.ProfileRepository>(
      () => _i597.ProfileRepositoryImpl(
        profileDataSource: gh<_i582.ProfileDataSource>(),
      ),
    );
    gh.factory<_i966.EmploeeStatisticsRemoteDataSource>(
      () => _i265.EmploeeStatisticsRemoteDataSourceImpl(
        apiManager: gh<_i949.ApiManager>(),
      ),
    );
    gh.factory<_i50.ProfileCubit>(
      () => _i50.ProfileCubit(gh<_i247.ProfileRepository>()),
    );
    gh.factory<_i825.EmploeeStatisticsRepo>(
      () => _i927.EmployeeStatisticsRepoImpl(
        gh<_i966.EmploeeStatisticsRemoteDataSource>(),
      ),
    );
    gh.factory<_i981.MyRequestsRepository>(
      () => _i1070.MyRequestsRepositoryImpl(
        myRequestsDataSource: gh<_i274.MyRequestsDataSource>(),
      ),
    );
    gh.factory<_i964.AdminLoginViewModel>(
      () => _i964.AdminLoginViewModel(gh<_i471.AuthRepository>()),
    );
    gh.factory<_i600.EmployeeLoginViewModel>(
      () => _i600.EmployeeLoginViewModel(gh<_i471.AuthRepository>()),
    );
    gh.factory<_i960.RequestsRepository>(
      () => _i1020.RequestsRepositoryImpl(
        requestsDataSource: gh<_i588.RequestsDataSource>(),
      ),
    );
    gh.factory<_i6.BloodSamplesCubit>(
      () => _i6.BloodSamplesCubit(gh<_i459.RequestsRepository>()),
    );
    gh.factory<_i497.BloodSampleCubit>(
      () => _i497.BloodSampleCubit(
        requestsRepository: gh<_i960.RequestsRepository>(),
      ),
    );
    gh.factory<_i692.MyRequestsCubit>(
      () => _i692.MyRequestsCubit(gh<_i981.MyRequestsRepository>()),
    );
    gh.factory<_i724.EmployeeHomeCubit>(
      () => _i724.EmployeeHomeCubit(gh<_i825.EmploeeStatisticsRepo>()),
    );
    return this;
  }
}
