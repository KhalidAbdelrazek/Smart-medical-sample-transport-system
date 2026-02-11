import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../domain/request_models.dart';
import 'blood_samples_state.dart';

/// Cubit for Blood Samples sub-tab
@injectable
class BloodSamplesCubit extends Cubit<BloodSamplesState> {
  BloodSamplesCubit() : super(BloodSamplesInitial());

  List<BloodSampleRequest> _pendingRequests = [];
  List<BloodSampleRequest> _addedToCarRequests = [];
  TransportCar _car = const TransportCar();

  /// Load requests with 2-second delay
  Future<void> loadRequests() async {
    emit(BloodSamplesLoading());
    try {
      await Future.delayed(const Duration(seconds: 2));
      _pendingRequests = _generateDummyRequests();
      _addedToCarRequests = [];
      _car = const TransportCar();
      _emitLoaded();
    } catch (e) {
      emit(BloodSamplesError('Failed to load requests'));
    }
  }

  /// Refresh requests (pull-to-refresh)
  Future<void> refresh() async {
    await loadRequests();
  }

  /// Add request to car
  void addToCar(String requestId) {
    if (_car.isFull) return;

    final index = _pendingRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final request = _pendingRequests[index].copyWith(
      status: RequestStatus.addedToCar,
    );

    _pendingRequests.removeAt(index);
    _addedToCarRequests.add(request);
    _car = _car.copyWith(currentLoad: _car.currentLoad + 1);

    _emitLoaded();
  }

  /// Remove request from car back to pending
  void removeFromCar(String requestId) {
    final index = _addedToCarRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final request = _addedToCarRequests[index].copyWith(
      status: RequestStatus.pending,
    );

    _addedToCarRequests.removeAt(index);
    _pendingRequests.add(request);
    _car = _car.copyWith(currentLoad: _car.currentLoad - 1);

    _emitLoaded();
  }

  /// Dispatch car - clears added items and resets car
  void dispatchCar() {
    if (_car.isEmpty) return;

    _addedToCarRequests.clear();
    _car = const TransportCar();

    _emitLoaded();
  }

  void _emitLoaded() {
    emit(
      BloodSamplesLoaded(
        pendingRequests: List.unmodifiable(_pendingRequests),
        addedToCarRequests: List.unmodifiable(_addedToCarRequests),
        car: _car,
      ),
    );
  }

  List<BloodSampleRequest> _generateDummyRequests() {
    return [
      const BloodSampleRequest(
        id: 'BS-001',
        patientId: 'PT-4521',
        sampleCount: 2,
        source: RequestSource.lab,
        sourceDetail: 'Lab B',
      ),
      const BloodSampleRequest(
        id: 'BS-002',
        patientId: 'PT-7823',
        sampleCount: 1,
        source: RequestSource.operationRoom,
        sourceDetail: 'OR-03',
      ),
      const BloodSampleRequest(
        id: 'BS-003',
        patientId: 'PT-1290',
        sampleCount: 3,
        source: RequestSource.lab,
        sourceDetail: 'Lab A',
      ),
      const BloodSampleRequest(
        id: 'BS-004',
        patientId: 'PT-5612',
        sampleCount: 1,
        source: RequestSource.operationRoom,
        sourceDetail: 'OR-11',
      ),
    ];
  }
}
