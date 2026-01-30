import 'package:smart_midecal_transport_app/presentation/employee/transport/domain/transport_model_entity.dart';


abstract class TransportState {}

class TransportInitial extends TransportState{}

class TransportLoading extends TransportState {}

class TransportLoaded extends TransportState {
  final List<TransportModelEntity> transports;
  TransportLoaded(this.transports);
}

class TransportFiltered extends TransportState {
  final List<TransportModelEntity> filtered;
  TransportFiltered(this.filtered);
}

