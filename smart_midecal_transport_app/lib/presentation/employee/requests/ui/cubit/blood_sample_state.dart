import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/samples_response_entity.dart';

/// States for Blood Sample Request
abstract class BloodSampleState {}

class BloodSampleInitial extends BloodSampleState {}

class BloodSampleLoading extends BloodSampleState {}

class BloodSampleSearchLoading extends BloodSampleState {}

class BloodSampleLoaded extends BloodSampleState {
  final List<SampleEntity> searchResults;
  final SampleEntity? selectedSample;
  final String? selectedRoom;

  BloodSampleLoaded({
    this.searchResults = const [],
    this.selectedSample,
    this.selectedRoom,
  });
}

class BloodSampleSubmitting extends BloodSampleState {}

class BloodSampleSuccess
    extends BloodSampleState {} // Added for successful submission

class BloodSampleError extends BloodSampleState {
  final String message;
  BloodSampleError(this.message);
}
