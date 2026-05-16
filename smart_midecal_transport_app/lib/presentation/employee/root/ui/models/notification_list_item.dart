import 'package:equatable/equatable.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/domain/entity/notification_response_entity.dart';

/// UI row for one pending delivery notification (merged from API + client `firstSeenAt`).
class NotificationListItem extends Equatable {
  const NotificationListItem({
    required this.requestId,
    required this.titleTrKey,
    required this.description,
    required this.roomLabel,
    required this.status,
    required this.firstSeenAt,
  });

  final String requestId;
  final String titleTrKey;
  final String description;
  final String roomLabel;
  final String? status;
  final DateTime firstSeenAt;

  static String descriptionFromEntity(NotificationArrivalsEntity e) {
    final parts = <String>[];
    final name = e.sampleName?.trim();
    if (name != null && name.isNotEmpty) {
      parts.add(name);
    }
    final code = e.sampleCode?.trim();
    if (code != null && code.isNotEmpty) {
      parts.add(code);
    }
    if (parts.isEmpty) {
      return '';
    }
    return parts.join(' · ');
  }

  static String roomFromEntity(NotificationArrivalsEntity e) {
    final r = e.room?.trim();
    if (r == null || r.isEmpty) {
      return '';
    }
    return r;
  }

  NotificationListItem mergedWith(
    NotificationArrivalsEntity e,
    DateTime preservedFirstSeen,
  ) {
    return NotificationListItem(
      requestId: requestId,
      titleTrKey: titleTrKey,
      description: descriptionFromEntity(e).isEmpty
          ? description
          : descriptionFromEntity(e),
      roomLabel: roomFromEntity(e).isEmpty ? roomLabel : roomFromEntity(e),
      status: e.status ?? status,
      firstSeenAt: preservedFirstSeen,
    );
  }

  @override
  List<Object?> get props => [
    requestId,
    titleTrKey,
    description,
    roomLabel,
    status,
    firstSeenAt,
  ];
}
