import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Domain/Repository/profile_repository.dart';
import 'profile_state.dart';

/// Cubit for Profile Tab
@injectable
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileCubit(this._profileRepository) : super(ProfileInitial());

  /// Load profile data
  Future<void> loadData() async {
    emit(ProfileLoading());

    final result = await _profileRepository.getProfile();

    result.fold(
      (failure) {
        final errorMsg = failure.errorMessage;
        final bool isTokenExpired = errorMsg.toLowerCase().contains('session expired') || 
            errorMsg.toLowerCase().contains('token_not_valid') ||
            errorMsg.toLowerCase().contains('motherfucker');
            
        emit(ProfileError(errorMsg, isTokenExpired: isTokenExpired));
      },
      (profile) {
        emit(ProfileLoaded(userProfile: profile));
      },
    );
  }

  /// Refresh profile (pull-to-refresh)
  Future<void> refresh() async {
    await loadData();
  }

  /// Logout
  Future<void> logout() async {
    await SharedPrefService.instance.clearTokens();
    await SharedPrefService.instance.clearRole();
    emit(ProfileLoggedOut());
  }
}
