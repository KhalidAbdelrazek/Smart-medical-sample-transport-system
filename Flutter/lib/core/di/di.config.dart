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
import '../../presentation/employee/root/data/data%20source/notification_ds.dart'
    as _i392;
import '../../presentation/employee/root/data/data%20source/notification_ds_impl.dart'
    as _i851;
import '../../presentation/employee/root/data/repository/notification_repository_impl.dart'
    as _i834;
import '../../presentation/employee/root/domain/repository/notification_repository.dart'
    as _i631;
import '../../presentation/employee/root/ui/cubit/notification_cubit.dart'
    as _i211;
import '../../presentation/employer/restrictions_tab/data/data_source/impl/restrictions_data_source_impl.dart'
    as _i131;
import '../../presentation/employer/restrictions_tab/data/data_source/restrictions_data_source.dart'
    as _i504;
import '../../presentation/employer/restrictions_tab/data/repos/restrictions_repository_impl.dart'
    as _i626;
import '../../presentation/employer/restrictions_tab/domain/repos/restrictions_repository.dart'
    as _i192;
import '../../presentation/employer/restrictions_tab/ui/cubit/restrictions_cubit.dart'
    as _i762;
import '../../presentation/employer/statistics_tab/data/data_source/admin_stats_data_source.dart'
    as _i392;
import '../../presentation/employer/statistics_tab/data/data_source/impl/admin_stats_data_source_impl.dart'
    as _i171;
import '../../presentation/employer/statistics_tab/data/repos/admin_stats_repository_impl.dart'
    as _i340;
import '../../presentation/employer/statistics_tab/domain/repos/admin_stats_repository.dart'
    as _i154;
import '../../presentation/employer/statistics_tab/ui/cubit/statistics_cubit.dart'
    as _i72;
import '../../presentation/storage/home_tab/data/data_source/impl/static_storage_remote_ds_impl.dart'
    as _i304;
import '../../presentation/storage/home_tab/data/data_source/static_storage_remote_ds.dart'
    as _i545;
import '../../presentation/storage/home_tab/data/repos/static_storage_repo.dart'
    as _i843;
import '../../presentation/storage/home_tab/domain/repos/static_storage_repo.dart'
    as _i771;
import '../../presentation/storage/home_tab/ui/cubit/home_cubit.dart' as _i592;
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
import '../notifications/notification_sound_service.dart' as _i786;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i949.ApiManager>(() => _i949.ApiManager());
    gh.lazySingleton<_i786.NotificationSoundService>(
      () => _i786.NotificationSoundService(),
    );
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
    gh.factory<_i545.StorageStatisticsRemoteDataSource>(
      () => _i304.StorageStatisticsRemoteDataSourceImpl(
        apiManager: gh<_i949.ApiManager>(),
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
    gh.factory<_i392.AdminStatsDataSource>(
      () => _i171.AdminStatsDataSourceImpl(apiManager: gh<_i949.ApiManager>()),
    );
    gh.factory<_i392.NotificationDataSource>(
      () => _i851.NotificationDsImpl(apiManager: gh<_i949.ApiManager>()),
    );
    gh.factory<_i504.RestrictionsDataSource>(
      () =>
          _i131.RestrictionsDataSourceImpl(apiManager: gh<_i949.ApiManager>()),
    );
    gh.factory<_i154.AdminStatsRepository>(
      () => _i340.AdminStatsRepositoryImpl(gh<_i392.AdminStatsDataSource>()),
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
    gh.factory<_i631.NotificationRepository>(
      () => _i834.NotificationRepositoryImpl(
        notificationDataSource: gh<_i392.NotificationDataSource>(),
      ),
    );
    gh.factory<_i211.NotificationCubit>(
      () => _i211.NotificationCubit(
        gh<_i631.NotificationRepository>(),
        gh<_i786.NotificationSoundService>(),
      ),
    );
    gh.factory<_i72.StatisticsCubit>(
      () => _i72.StatisticsCubit(gh<_i154.AdminStatsRepository>()),
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
    gh.factory<_i771.StorageStatisticsRepo>(
      () => _i843.StorageStatisticsRepoImpl(
        gh<_i545.StorageStatisticsRemoteDataSource>(),
      ),
    );
    gh.factory<_i192.RestrictionsRepository>(
      () =>
          _i626.RestrictionsRepositoryImpl(gh<_i504.RestrictionsDataSource>()),
    );
    gh.factory<_i592.HomeCubit>(
      () => _i592.HomeCubit(gh<_i771.StorageStatisticsRepo>()),
    );
    gh.factory<_i762.RestrictionsCubit>(
      () => _i762.RestrictionsCubit(gh<_i192.RestrictionsRepository>()),
    );
    return this;
  }
}
