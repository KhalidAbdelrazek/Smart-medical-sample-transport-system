import 'package:smart_midecal_transport_app/core/api%20manager/api_constants.dart';

abstract class ApiEndPoints {
  static const employeeLogin = '${ApiConstants.baseUrl}api/auth/login/';
  static const adminLogin = '${ApiConstants.baseUrl}api/auth/admin/login/';
  static const getProfile = '${ApiConstants.baseUrl}api/auth/profile/';
  static const getSampleById = '${ApiConstants.baseUrl}api/samples/';
  static const requestSample = '${ApiConstants.baseUrl}api/samples/request/';
  static const requestBulkSample =
      '${ApiConstants.baseUrl}api/samples/request-bulk/';
  static const getRequests = '${ApiConstants.baseUrl}api/transport/requests/';
  static const addToCar = '${ApiConstants.baseUrl}/api/transport/add-to-car/';
  static const dispatchCar =
      '${ApiConstants.baseUrl}/api/transport/dispatch-car/';

  static const statisticsDashboard = '${ApiConstants.baseUrl}api/analytics/dashboard/';

  // ── Restrictions ──────────────────────────────────────────────────────────
  static const restrictionsStatus =
      '${ApiConstants.baseUrl}api/restrictions/status/';
  static const restrictDoctorSamples =
      '${ApiConstants.baseUrl}api/restrictions/restrict-doctor-samples/';
  static const restrictStorageSamples =
      '${ApiConstants.baseUrl}api/restrictions/restrict-storage-samples/';
  static const restrictTransportCar =
      '${ApiConstants.baseUrl}api/restrictions/restrict-transport-car/';

  // ── People lists (for partial restriction selection) ──────────────────────
  static const getDoctors = '${ApiConstants.baseUrl}api/auth/doctors/';
  static const getStorageEmployees =
      '${ApiConstants.baseUrl}api/auth/storage-employees/';

  // ── My Requests (Employee / Doctor) ──────────────────────────────────────
  static const getMyTransportRequests =
      '${ApiConstants.baseUrl}api/transport/my-requests/';
  static String cancelTransportRequest(String id) =>
      '${ApiConstants.baseUrl}api/transport/requests/$id/cancel/';

  // todo : chatbot =>
  // static const chatbot = '${ApiConstants.chatbotUrl}/chat';

  // // todo : Tours =>
  // static const getHotels = '${ApiConstants.baseUrl}/hotel/gethotels';
  // static const getTrips = '${ApiConstants.baseUrl}/trip/gettrips';
  // static const register = '${ApiConstants.baseUrl}/user/signup';
  // static const login = '${ApiConstants.baseUrl}/user/login';
  // static const resetPassword = '${ApiConstants.baseUrl}/user/forgotpass';
  // static const getWishlist = '${ApiConstants.baseUrl}/trip/wishlist';
  // static const postTrip = '${ApiConstants.baseUrl}/trip/addtrip';
  // static const postHotel = '${ApiConstants.baseUrl}/hotel';

  // static String setFav(String tripId) =>
  //     "${ApiConstants.baseUrl}/user/addwishlist/$tripId";
  // static String notFav(String tripId) =>
  //     "${ApiConstants.baseUrl}/trip/deletewishlist/$tripId";

  // static String bookTrip(String tripId) =>
  //     "${ApiConstants.baseUrl}/book/$tripId";
  // static String bookHotel(String hotelId) =>
  //     "${ApiConstants.baseUrl}/bookhotel/$hotelId";
}
