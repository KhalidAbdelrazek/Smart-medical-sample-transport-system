/// States for Blood Sample Request
abstract class BloodSampleState {}

class BloodSampleInitial extends BloodSampleState {}

class BloodSampleLoading extends BloodSampleState {}

class BloodSampleLoaded extends BloodSampleState {}

class BloodSampleSubmitting extends BloodSampleState {}

class BloodSampleError extends BloodSampleState {
  final String message;
  BloodSampleError(this.message);
}
