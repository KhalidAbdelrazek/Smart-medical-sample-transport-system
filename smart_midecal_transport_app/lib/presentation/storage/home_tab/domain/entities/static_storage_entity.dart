class StorageStatisticsEntity {
  final int totalactions;
  final int cardispatch;
  final int sampleaddedtocar;
  final int sampleremovedfromcar;
  final int transportrequestupdate;
  final double other;
  final String period;
  final String role;

  StorageStatisticsEntity({
    required this.totalactions,
    required this.cardispatch,
    required this.sampleaddedtocar,
    required this.sampleremovedfromcar,
    required this.transportrequestupdate,
    required this.other,
    required this.period,
    required this.role,
  });
}
