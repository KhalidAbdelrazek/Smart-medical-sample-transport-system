class StatisticsEntity {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final int cancelledRequests;
  final int pendingRequests;
  final double successRate;
  final String period;
  final String role;

  StatisticsEntity({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.cancelledRequests,
    required this.pendingRequests,
    required this.successRate,
    required this.period,
    required this.role,
  });
}