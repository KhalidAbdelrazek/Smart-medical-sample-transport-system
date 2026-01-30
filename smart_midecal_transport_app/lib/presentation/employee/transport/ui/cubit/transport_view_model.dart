import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/presentation/employee/transport/domain/transport_model_entity.dart';
import 'transport_states.dart';


@injectable
class TransportViewModel extends Cubit<TransportState> {
  TransportViewModel() : super(TransportInitial());

  List<TransportModelEntity> allTransports = [
    TransportModelEntity(
      id: "TRP001",
      status: "pending",
      code: "BB001234",
      pickup: "Blood Bank - Building A",
      dropoff: "ER - Room 301",
      person: "Alex Johnson",
      time: "10:30 AM",
    ),
    TransportModelEntity(
      id: "TRP002",
      status: "urgent",
      code: "BB001235",
      pickup: "Storage Unit B",
      dropoff: "ICU - Room 205",
      person: "Maria Garcia",
      time: "11:00 AM",
    ),
    TransportModelEntity(
      id: "TRP003",
      status: "completed",
      code: "BB001236",
      pickup: "Lab C",
      dropoff: "Surgery Room 2",
      person: "James Wilson",
      time: "9:15 AM",
    ),
    TransportModelEntity(
      id: "TRP004",
      status: "pending",
      code: "BB001237",
      pickup: "Blood Bank - Building A",
      dropoff: "Ward 3 - Bed 12",
      person: "Sarah Chen",
      time: "2:00 PM",
    ),
  ];

  void loadTransports() {
    emit(TransportLoaded(allTransports));
  }

  void filterByStatus(String status) {
    if (status == 'all_status') {
      emit(TransportFiltered(allTransports));
    } else {
      final filtered =
          allTransports.where((t) => t.status == status).toList();
      emit(TransportFiltered(filtered));
    }
  }
}


