import 'package:equatable/equatable.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/models/notification_list_item.dart';

class NotificationState extends Equatable {
  const NotificationState({
    required this.isInitialLoading,
    required this.items,
    required this.actionInFlightIds,
    required this.enteringIds,
    this.lastSuccessMessage,
    this.lastErrorMessage,
  });

  factory NotificationState.initial() => const NotificationState(
        isInitialLoading: true,
        items: [],
        actionInFlightIds: {},
        enteringIds: {},
      );

  final bool isInitialLoading;
  final List<NotificationListItem> items;
  final Set<String> actionInFlightIds;
  final Set<String> enteringIds;
  final String? lastSuccessMessage;
  final String? lastErrorMessage;

  NotificationState copyWith({
    bool? isInitialLoading,
    List<NotificationListItem>? items,
    Set<String>? actionInFlightIds,
    Set<String>? enteringIds,
  }) {
    return NotificationState(
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      items: items ?? this.items,
      actionInFlightIds: actionInFlightIds ?? this.actionInFlightIds,
      enteringIds: enteringIds ?? this.enteringIds,
      lastSuccessMessage: lastSuccessMessage,
      lastErrorMessage: lastErrorMessage,
    );
  }

  NotificationState withMessagesCleared() => NotificationState(
        isInitialLoading: isInitialLoading,
        items: items,
        actionInFlightIds: actionInFlightIds,
        enteringIds: enteringIds,
      );

  NotificationState withSuccess(String message) => NotificationState(
        isInitialLoading: isInitialLoading,
        items: items,
        actionInFlightIds: actionInFlightIds,
        enteringIds: enteringIds,
        lastSuccessMessage: message,
      );

  NotificationState withError(String message) => NotificationState(
        isInitialLoading: isInitialLoading,
        items: items,
        actionInFlightIds: actionInFlightIds,
        enteringIds: enteringIds,
        lastErrorMessage: message,
      );

  /// Snapshot for poll merge: ignore transient snackbar fields.
  String get dataSignature {
    final actions = List<String>.from(actionInFlightIds)..sort();
    final entering = List<String>.from(enteringIds)..sort();
    final buf = StringBuffer()
      ..write(isInitialLoading)
      ..write('|')
      ..write(actions.join(','))
      ..write('|')
      ..write(entering.join(','))
      ..write('|');
    for (final i in items) {
      buf
        ..write(i.requestId)
        ..write(':')
        ..write(i.description)
        ..write(':')
        ..write(i.roomLabel)
        ..write(':')
        ..write(i.status)
        ..write(':')
        ..write(i.firstSeenAt.millisecondsSinceEpoch)
        ..write(';');
    }
    return buf.toString();
  }

  @override
  List<Object?> get props => [
        isInitialLoading,
        items,
        actionInFlightIds,
        enteringIds,
        lastSuccessMessage,
        lastErrorMessage,
      ];
}
