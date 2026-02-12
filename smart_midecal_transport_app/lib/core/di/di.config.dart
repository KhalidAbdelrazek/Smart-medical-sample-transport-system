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

import '../../presentation/authentication/ui/cubit/sign_in_cubit.dart' as _i832;
import '../../presentation/employee/home/cubit/employee_home_cubit.dart'
    as _i289;
import '../../presentation/employee/profile/cubit/employee_profile_cubit.dart'
    as _i354;
import '../../presentation/employee/requests/cubit/blood_bag_cubit.dart'
    as _i424;
import '../../presentation/employee/requests/cubit/blood_sample_cubit.dart'
    as _i339;
import '../../presentation/employer/profile_tab/cubit/employer_profile_cubit.dart'
    as _i732;
import '../../presentation/employer/restrictions_tab/cubit/restrictions_cubit.dart'
    as _i963;
import '../../presentation/employer/statistics_tab/cubit/statistics_cubit.dart'
    as _i327;
import '../../presentation/storage/home_tab/cubit/home_cubit.dart' as _i385;
import '../../presentation/storage/profile_tab/cubit/profile_cubit.dart'
    as _i349;
import '../../presentation/storage/requests_tab/cubit/blood_bags_cubit.dart'
    as _i599;
import '../../presentation/storage/requests_tab/cubit/blood_samples_cubit.dart'
    as _i186;
import '../api%20manager/api_manager.dart' as _i949;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i832.SignInCubit>(() => _i832.SignInCubit());
    gh.factory<_i289.EmployeeHomeCubit>(() => _i289.EmployeeHomeCubit());
    gh.factory<_i354.EmployeeProfileCubit>(() => _i354.EmployeeProfileCubit());
    gh.factory<_i424.BloodBagCubit>(() => _i424.BloodBagCubit());
    gh.factory<_i339.BloodSampleCubit>(() => _i339.BloodSampleCubit());
    gh.factory<_i732.EmployerProfileCubit>(() => _i732.EmployerProfileCubit());
    gh.factory<_i963.RestrictionsCubit>(() => _i963.RestrictionsCubit());
    gh.factory<_i327.StatisticsCubit>(() => _i327.StatisticsCubit());
    gh.factory<_i385.HomeCubit>(() => _i385.HomeCubit());
    gh.factory<_i349.ProfileCubit>(() => _i349.ProfileCubit());
    gh.factory<_i599.BloodBagsCubit>(() => _i599.BloodBagsCubit());
    gh.factory<_i186.BloodSamplesCubit>(() => _i186.BloodSamplesCubit());
    gh.singleton<_i949.ApiManager>(() => _i949.ApiManager());
    return this;
  }
}
