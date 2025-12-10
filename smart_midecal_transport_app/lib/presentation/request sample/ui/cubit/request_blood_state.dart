abstract class RequestBloodSamplesStates{}

class RequestBloodInitState extends RequestBloodSamplesStates {}


class SuccessState extends RequestBloodSamplesStates {
  dynamic response;
  SuccessState({required this.response});
}

class ErrorState extends RequestBloodSamplesStates {
  String errorMessage;
  ErrorState({required this.errorMessage});
}