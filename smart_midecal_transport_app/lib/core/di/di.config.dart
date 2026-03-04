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
import '../../presentation/employee/home/cubit/employee_home_cubit.dart'
    as _i289;
import '../../presentation/employee/profile/cubit/employee_profile_cubit.dart'
    as _i354;
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
import '../../presentation/employer/profile_tab/cubit/employer_profile_cubit.dart'
    as _i732;
import '../../presentation/employer/restrictions_tab/cubit/restrictions_cubit.dart'
    as _i963;
import '../../presentation/employer/statistics_tab/cubit/statistics_cubit.dart'
    as _i327;
import '../../presentation/storage/home_tab/cubit/home_cubit.dart' as _i385;
import '../../presentation/storage/profile_tab/cubit/profile_cubit.dart'
    as _i349;
import '../../presentation/storage/requests_tab/data/data%20source/requests_data_source.dart'
    as _i800;
import '../../presentation/storage/requests_tab/data/data%20source/requests_data_source_impl.dart'
    as _i801;
import '../../presentation/storage/requests_tab/data/repository/requests_repository_impl.dart'
    as _i802;
import '../../presentation/storage/requests_tab/domain/repository/requests_repository.dart'
    as _i803;
import '../../presentation/storage/requests_tab/ui/cubit/blood_samples_cubit.dart'
    as _i186;
import '../api%20manager/api_manager.dart' as _i949;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i289.EmployeeHomeCubit>(() => _i289.EmployeeHomeCubit());
    gh.factory<_i354.EmployeeProfileCubit>(() => _i354.EmployeeProfileCubit());
    gh.factory<_i732.EmployerProfileCubit>(() => _i732.EmployerProfileCubit());
    gh.factory<_i963.RestrictionsCubit>(() => _i963.RestrictionsCubit());
    gh.factory<_i327.StatisticsCubit>(() => _i327.StatisticsCubit());
    gh.factory<_i385.HomeCubit>(() => _i385.HomeCubit());
    gh.factory<_i349.ProfileCubit>(() => _i349.ProfileCubit());
    gh.factory<_i800.RequestsDataSource>(
      () => _i801.RequestsDataSourceImpl(apiManager: gh<_i949.ApiManager>()),
    );
    gh.factory<_i803.RequestsRepository>(
      () => _i802.RequestsRepositoryImpl(
        requestsDataSource: gh<_i800.RequestsDataSource>(),
      ),
    );
    gh.factory<_i186.BloodSamplesCubit>(
      () => _i186.BloodSamplesCubit(gh<_i803.RequestsRepository>()),
    );
    gh.singleton<_i949.ApiManager>(() => _i949.ApiManager());
    gh.factory<_i727.AuthRemoteDataSource>(
      () => _i1029.AuthRemoteDataSourceImpl(apiManager: gh<_i949.ApiManager>()),
    );
    gh.factory<_i471.AuthRepository>(
      () => _i659.AuthRepositoryImpl(
        authRemoteDataSource: gh<_i727.AuthRemoteDataSource>(),
      ),
    );
    gh.factory<_i588.RequestsDataSource>(
      () => _i128.RequestsDataSourceImpl(apiManager: gh<_i949.ApiManager>()),
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
    gh.factory<_i497.BloodSampleCubit>(
      () => _i497.BloodSampleCubit(
        requestsRepository: gh<_i960.RequestsRepository>(),
      ),
    );
    return this;
  }
}
