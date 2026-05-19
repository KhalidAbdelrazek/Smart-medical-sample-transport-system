import 'package:equatable/equatable.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/domain/entity/notification_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/models/notification_list_item.dart';

class NotificationState extends Equatable {
  const NotificationState({
    required this.isInitialLoading,
    required this.items,
    required this.actionInFlightIds,
    required this.enteringIds,
    this.returnableSamples = const [],
    this.returnOffer = false,
    this.lastSuccessMessage,
    this.lastErrorMessage,
  });

  factory NotificationState.initial() => const NotificationState(
    isInitialLoading: true,
    items: [],
    actionInFlightIds: {},
    enteringIds: {},
    returnableSamples: [],
    returnOffer: false,
  );

  final bool isInitialLoading;
  final List<NotificationListItem> items;
  final Set<String> actionInFlightIds;
  final Set<String> enteringIds;
  final List<ReturnableSamplesEntity> returnableSamples;
  final bool returnOffer;
  final String? lastSuccessMessage;
  final String? lastErrorMessage;

  NotificationState copyWith({
    bool? isInitialLoading,
    List<NotificationListItem>? items,
    Set<String>? actionInFlightIds,
    Set<String>? enteringIds,
    List<ReturnableSamplesEntity>? returnableSamples,
    bool? returnOffer,
  }) {
    return NotificationState(
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      items: items ?? this.items,
      actionInFlightIds: actionInFlightIds ?? this.actionInFlightIds,
      enteringIds: enteringIds ?? this.enteringIds,
      returnableSamples: returnableSamples ?? this.returnableSamples,
      returnOffer: returnOffer ?? this.returnOffer,
      lastSuccessMessage: lastSuccessMessage,
      lastErrorMessage: lastErrorMessage,
    );
  }

  NotificationState withMessagesCleared() => NotificationState(
    isInitialLoading: isInitialLoading,
    items: items,
    actionInFlightIds: actionInFlightIds,
    enteringIds: enteringIds,
    returnableSamples: returnableSamples,
    returnOffer: returnOffer,
  );

  NotificationState withSuccess(String message) => NotificationState(
    isInitialLoading: isInitialLoading,
    items: items,
    actionInFlightIds: actionInFlightIds,
    enteringIds: enteringIds,
    returnableSamples: returnableSamples,
    returnOffer: returnOffer,
    lastSuccessMessage: message,
  );

  NotificationState withError(String message) => NotificationState(
    isInitialLoading: isInitialLoading,
    items: items,
    actionInFlightIds: actionInFlightIds,
    enteringIds: enteringIds,
    returnableSamples: returnableSamples,
    returnOffer: returnOffer,
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
      ..write('|')
      ..write(returnOffer)
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
    returnableSamples,
    returnOffer,
    lastSuccessMessage,
    lastErrorMessage,
  ];
}
