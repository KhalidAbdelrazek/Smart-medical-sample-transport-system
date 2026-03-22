import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Domain/Entity/get_profle_entity.dart';

/// States for Profile Tab
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final GetProfileEntity userProfile;

  ProfileLoaded({required this.userProfile});
}

class ProfileLoggedOut extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  final bool isTokenExpired;

  ProfileError(this.message, {this.isTokenExpired = false});
}
