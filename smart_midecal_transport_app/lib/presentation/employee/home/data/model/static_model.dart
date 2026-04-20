import 'package:smart_midecal_transport_app/presentation/employee/home/domain/entites/static_entity.dart';

class EmploeeStatisticsModel extends EmploeeStatisticsEntity {
  EmploeeStatisticsModel({
    required super.totalRequests,
    required super.successfulRequests,
    required super.failedRequests,
    required super.cancelledRequests,
    required super.pendingRequests,
    required super.successRate,
    required super.period,
    required super.role,
  });

  factory EmploeeStatisticsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    return EmploeeStatisticsModel(
      totalRequests: data['total_requests'],
      successfulRequests: data['successful_requests'],
      failedRequests: data['failed_requests'],
      cancelledRequests: data['cancelled_requests'],
      pendingRequests: data['pending_requests'],
      successRate: (data['success_rate'] as num).toDouble(),
      period: data['period'],
      role: data['role'],
    );
  }
}