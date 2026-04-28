import 'package:smart_midecal_transport_app/presentation/employee/return_flow/domain/entities/return_status_entity.dart';

class ReturnPollingState {
  final String? activeBatchId;
  final List<ReturnStatusEntity> activeSamples;
  final bool isConfirming;
  final bool tokenExpired;
  final String? toastMessage;

  const ReturnPollingState({
    required this.activeBatchId,
    required this.activeSamples,
    required this.isConfirming,
    required this.tokenExpired,
    required this.toastMessage,
  });

  bool get hasBlockingPopup => activeBatchId != null && activeSamples.isNotEmpty;

  factory ReturnPollingState.initial() {
    return const ReturnPollingState(
      activeBatchId: null,
      activeSamples: [],
      isConfirming: false,
      tokenExpired: false,
      toastMessage: null,
    );
  }

  ReturnPollingState copyWith({
    String? activeBatchId,
    bool clearBatch = false,
    List<ReturnStatusEntity>? activeSamples,
    bool? isConfirming,
    bool? tokenExpired,
    String? toastMessage,
    bool clearToast = false,
  }) {
    return ReturnPollingState(
      activeBatchId: clearBatch ? null : (activeBatchId ?? this.activeBatchId),
      activeSamples: clearBatch ? [] : (activeSamples ?? this.activeSamples),
      isConfirming: isConfirming ?? this.isConfirming,
      tokenExpired: tokenExpired ?? this.tokenExpired,
      toastMessage: clearToast ? null : (toastMessage ?? this.toastMessage),
    );
  }
}
