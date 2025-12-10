import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/presentation/request%20sample/ui/cubit/request_blood_state.dart';

@injectable
class RequestBloodViewModel extends Cubit<RequestBloodSamplesStates> {
  RequestBloodViewModel() : super(RequestBloodInitState());

  final TextEditingController patientController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String? selectedBloodType;
  String urgency = 'normal';

  List<String> bloodTypes = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];

  final List<Map<String, dynamic>> recentRequests = [
    {
      "name": "John Doe",
      "blood": "O+",
      "time": "2 hours ago",
      "status": "pending",
    },
    {
      "name": "Jane Smith",
      "blood": "A-",
      "time": "5 hours ago",
      "status": "completed",
    },
    {
      "name": "Bob Wilson",
      "blood": "B+",
      "time": "1 day ago",
      "status": "completed",
    },
  ];
}
