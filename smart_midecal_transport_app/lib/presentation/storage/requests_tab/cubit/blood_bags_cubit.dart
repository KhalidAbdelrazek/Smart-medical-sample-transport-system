import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../domain/request_models.dart';
import 'blood_bags_state.dart';

/// Cubit for Blood Bags sub-tab
@injectable
class BloodBagsCubit extends Cubit<BloodBagsState> {
  BloodBagsCubit() : super(BloodBagsInitial());

  List<BloodBagRequest> _pendingRequests = [];
  List<BloodBagRequest> _addedToCarRequests = [];
  TransportCar _car = const TransportCar();

  /// Load requests with 2-second delay
  Future<void> loadRequests() async {
    emit(BloodBagsLoading());
    try {
      await Future.delayed(const Duration(seconds: 2));
      _pendingRequests = _generateDummyRequests();
      _addedToCarRequests = [];
      _car = const TransportCar();
      _emitLoaded();
    } catch (e) {
      emit(BloodBagsError('Failed to load requests'));
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
      BloodBagsLoaded(
        pendingRequests: List.unmodifiable(_pendingRequests),
        addedToCarRequests: List.unmodifiable(_addedToCarRequests),
        car: _car,
      ),
    );
  }

  List<BloodBagRequest> _generateDummyRequests() {
    return [
      const BloodBagRequest(
        id: 'BB-001',
        bloodType: BloodType.aPositive,
        quantity: 2,
        source: RequestSource.operationRoom,
        sourceDetail: 'OR-12',
      ),
      const BloodBagRequest(
        id: 'BB-002',
        bloodType: BloodType.oNegative,
        quantity: 3,
        source: RequestSource.lab,
        sourceDetail: 'Lab A',
      ),
      const BloodBagRequest(
        id: 'BB-003',
        bloodType: BloodType.bPositive,
        quantity: 1,
        source: RequestSource.operationRoom,
        sourceDetail: 'OR-05',
      ),
      const BloodBagRequest(
        id: 'BB-004',
        bloodType: BloodType.abNegative,
        quantity: 2,
        source: RequestSource.lab,
        sourceDetail: 'Lab C',
      ),
      const BloodBagRequest(
        id: 'BB-005',
        bloodType: BloodType.oPositive,
        quantity: 1,
        source: RequestSource.operationRoom,
        sourceDetail: 'OR-08',
      ),
    ];
  }
}
