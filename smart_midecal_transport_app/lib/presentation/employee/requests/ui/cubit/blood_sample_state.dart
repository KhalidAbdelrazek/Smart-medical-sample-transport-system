import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/bulk_request_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/samples_response_entity.dart';

/// States for Blood Sample Request
abstract class BloodSampleState {}

class BloodSampleInitial extends BloodSampleState {}

class BloodSampleLoading extends BloodSampleState {}

class BloodSampleSearchLoading extends BloodSampleState {}

class BloodSampleLoaded extends BloodSampleState {
  final List<SampleEntity> searchResults;
  final List<String> selectedSampleCodes;
  final String? selectedRoom;

  BloodSampleLoaded({
    this.searchResults = const [],
    this.selectedSampleCodes = const [],
    this.selectedRoom,
  });
}

class BloodSampleSubmitting extends BloodSampleState {}

/// Emitted after a successful bulk API call (may be partial).
class BloodSampleBulkResult extends BloodSampleState {
  final int successCount;
  final int failureCount;
  final List<BulkSampleFailedEntity> failures;

  BloodSampleBulkResult({
    required this.successCount,
    required this.failureCount,
    required this.failures,
  });
}

/// Emitted when the API returns token_not_valid – triggers re-auth in the UI.
class BloodSampleTokenExpired extends BloodSampleState {}

class BloodSampleError extends BloodSampleState {
  final String message;
  BloodSampleError(this.message);
}
