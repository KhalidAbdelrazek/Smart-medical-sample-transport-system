import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/presentation/employee/request%20sample/ui/cubit/request_blood_state.dart';

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
      "name": "request_sample.example_requests.john_doe".tr(),
      "blood": "O+",
      "time": "2 hours ago",
      "status": "pending",
    },
    {
      "name": "request_sample.example_requests.jane_smith".tr(),
      "blood": "A-",
      "time": "5 hours ago",
      "status": "completed",
    },
    {
      "name": "request_sample.example_requests.bob_wilson".tr(),
      "blood": "B+",
      "time": "1 day ago",
      "status": "completed",
    },
  ];
}
