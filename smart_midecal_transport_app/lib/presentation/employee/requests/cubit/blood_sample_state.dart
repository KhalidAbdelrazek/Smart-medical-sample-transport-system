/// States for Blood Sample Request
abstract class BloodSampleState {}

class BloodSampleInitial extends BloodSampleState {}

class BloodSampleLoading extends BloodSampleState {}

class BloodSampleLoaded extends BloodSampleState {
  final List<Map<String, dynamic>> recentRequests;

  BloodSampleLoaded({required this.recentRequests});
}

class BloodSampleSubmitting extends BloodSampleState {}

class BloodSampleError extends BloodSampleState {
  final String message;
  BloodSampleError(this.message);
}
