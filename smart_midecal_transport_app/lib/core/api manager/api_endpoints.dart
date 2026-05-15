import 'package:smart_midecal_transport_app/core/api%20manager/api_constants.dart';

abstract class ApiEndPoints {
  static const employeeLogin = '${ApiConstants.baseUrl}api/auth/login/';
  static const adminLogin = '${ApiConstants.baseUrl}api/auth/admin/login/';
  static const getProfile = '${ApiConstants.baseUrl}api/auth/profile/';
  static const getSampleById = '${ApiConstants.baseUrl}api/samples/';
  static const requestBulkSample =
      '${ApiConstants.baseUrl}api/samples/request-bulk/';
  static const getRequests = '${ApiConstants.baseUrl}api/transport/requests/';
  static const addToCar = '${ApiConstants.baseUrl}/api/transport/add-to-car/';
  static const dispatchCar =
      '${ApiConstants.baseUrl}/api/transport/dispatch-car/';

  static const statisticsDashboard =
      '${ApiConstants.baseUrl}api/analytics/dashboard/';

  // ── Restrictions ──────────────────────────────────────────────────────────
  static String restrictionsStatus (String type) =>
      '${ApiConstants.baseUrl}api/restrictions/status/$type/';
  static const restrictDoctorSamples =
      '${ApiConstants.baseUrl}api/restrictions/restrict-doctor-samples/';
  static const restrictStorageSamples =
      '${ApiConstants.baseUrl}api/restrictions/restrict-storage-samples/';
  static const restrictTransportCar =
      '${ApiConstants.baseUrl}api/restrictions/restrict-transport-car/';

  // ── My Requests (Employee / Doctor) ──────────────────────────────────────
  static const getMyTransportRequests =
      '${ApiConstants.baseUrl}api/transport/my-requests/';
  static String cancelTransportRequest(String id) =>
      '${ApiConstants.baseUrl}api/transport/requests/$id/cancel/';
  static String removeFromCar(String id) =>
      '${ApiConstants.baseUrl}/api/transport/requests/$id/remove-from-cart/';

  //── notifications ──────────────────────────────────────────────────────
  static const notifications =
      '${ApiConstants.baseUrl}/api/transport/arrivals/';
  static String confirmDelivery(String requestId) =>
      '${ApiConstants.baseUrl}api/transport/requests/$requestId/confirm-delivery/';
  static String rejectDelivery(String requestId) =>
      '${ApiConstants.baseUrl}api/transport/requests/$requestId/reject-delivery/';

  static String getCar = '${ApiConstants.baseUrl}/api/transport/returned-cars/';
  static String confirmReturnedCar =
      '${ApiConstants.baseUrl}/api/transport/confirm-car-return/';

 static String confirmReturnHandoff() =>
      '${ApiConstants.baseUrl}/api/transport/confirm-return-handoff/';     
}
