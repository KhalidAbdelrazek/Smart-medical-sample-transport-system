import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/notifications/notification_sound_service.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/domain/entity/notification_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/domain/repository/notification_repository.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/cubit/notification_state.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/models/notification_list_item.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/ui/widgets/hand_off_widgit.dart';

@injectable
class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit(
    this._repository,
    this._soundService,
  ) : super(NotificationState.initial());

  final NotificationRepository _repository;
  final NotificationSoundService _soundService;

  Timer? _pollTimer;
  bool _fetchInFlight = false;

  void startPolling() {
    _pollTimer?.cancel();
    unawaited(_fetchAndMerge());
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_fetchAndMerge()),
    );
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }

  void clearMessages() {
    emit(state.withMessagesCleared());
  }

  void acknowledgeEntryAnimation(String requestId) {
    if (!state.enteringIds.contains(requestId)) return;
    final nextEntering = Set<String>.from(state.enteringIds)
      ..remove(requestId);
    final next = state.copyWith(enteringIds: nextEntering);
    if (next.dataSignature != state.dataSignature) {
      emit(next);
    }
  }

  Future<void> _fetchAndMerge() async {
    if (_fetchInFlight || isClosed) return;
    _fetchInFlight = true;
    try {
      final result = await _repository.getNotifications();
      if (isClosed) return;
      result.fold(
        (failure) {
          emit(state.withError(failure.errorMessage));
        },
        (response) {
          final rows = response.data?.arrivals ??
              const <NotificationArrivalsEntity>[];
          final returnOffer = response.data?.returnOffer ?? false;
          final returnableSamples =
              response.data?.returnableSamples ?? const [];

          final merged = _mergeApiRows(rows, state);
          final withExtra = merged.copyWith(
            returnOffer: returnOffer,
            returnableSamples: returnableSamples,
          );

          if (withExtra.dataSignature == state.dataSignature) return;

          final previousIds =
              state.items.map((e) => e.requestId).toSet();
          final newIds = withExtra.items
              .map((e) => e.requestId)
              .where((id) => !previousIds.contains(id))
              .toSet();
          final playSound =
              !state.isInitialLoading && newIds.isNotEmpty;
          String? soundStatus;
          if (playSound) {
            for (final e in withExtra.items) {
              if (!newIds.contains(e.requestId)) continue;
              final s = e.status?.trim();
              if (s != null && s.isNotEmpty) {
                soundStatus = s;
                break;
              }
            }
          }
          emit(withExtra);
          if (playSound && !isClosed) {
            unawaited(
              _soundService.playNewNotificationSound(status: soundStatus),
            );
          }
        },
      );
    } finally {
      _fetchInFlight = false;
    }
  }

  NotificationState _mergeApiRows(
    List<NotificationArrivalsEntity> rows,
    NotificationState current,
  ) {
    final prevById = {for (final i in current.items) i.requestId: i};
    final seen = <String>{};
    final merged = <NotificationListItem>[];

    for (final e in rows) {
      final rawId = e.requestId?.trim();
      if (rawId == null || rawId.isEmpty || seen.contains(rawId)) continue;
      seen.add(rawId);
      final prev = prevById[rawId];
      if (prev == null) {
        merged.add(
          NotificationListItem(
            requestId: rawId,
            titleTrKey: 'employee.notifications_delivery_title',
            description: NotificationListItem.descriptionFromEntity(e),
            roomLabel: NotificationListItem.roomFromEntity(e),
            status: e.status,
            firstSeenAt: DateTime.now(),
          ),
        );
      } else {
        merged.add(prev.mergedWith(e, prev.firstSeenAt));
      }
    }

    merged.sort((a, b) => b.firstSeenAt.compareTo(a.firstSeenAt));

    final mergedIds = merged.map((m) => m.requestId).toSet();
    final entering = <String>{
      for (final id in current.enteringIds)
        if (mergedIds.contains(id)) id,
    };
    for (final item in merged) {
      if (!prevById.containsKey(item.requestId)) {
        entering.add(item.requestId);
      }
    }

    return NotificationState(
      isInitialLoading: false,
      items: merged,
      actionInFlightIds: current.actionInFlightIds,
      enteringIds: entering,
      returnOffer: current.returnOffer,
      returnableSamples: current.returnableSamples,
      lastSuccessMessage: current.lastSuccessMessage,
      lastErrorMessage: current.lastErrorMessage,
    );
  }

  // ─────────────────────────────────────────────
  // Accept: show return-handoff dialog first
  // ─────────────────────────────────────────────

  /// Called when the user taps "Accept" on a notification card.
  /// If [returnOffer] is true, shows the return-handoff dialog.
  /// After the user decides, calls [confirmDelivery] then [confirmReturnHandoff].
  Future<void> onAcceptTapped(
    BuildContext context,
    String requestId,
  ) async {
    if (state.actionInFlightIds.contains(requestId)) return;

    if (state.returnOffer && state.returnableSamples.isNotEmpty) {
      // Show the dialog and wait for the user's selection.
      // null means the dialog was dismissed without a decision.
      final selectedCodes = await ReturnHandoffDialog.show(
        context,
        returnableSamples: state.returnableSamples,
      );
      if (selectedCodes == null) return; // user dismissed — do nothing
      await _runConfirmDelivery(requestId, selectedCodes);
    } else {
      // No return offer — just confirm delivery with an empty list.
      await _runConfirmDelivery(requestId, const []);
    }
  }

  Future<void> _runConfirmDelivery(
  String requestId,
  List<String> sampleCodes,
) async {
  emit(
    state.copyWith(
      actionInFlightIds: {...state.actionInFlightIds, requestId},
    ),
  );

  // 1️⃣ Confirm the delivery
  final deliveryResult =
      await _repository.confirmDelivery(requestId: requestId);
  if (isClosed) return;

  final deliveryError = deliveryResult.fold((f) => f.errorMessage, (_) => null);
  if (deliveryError != null) {
    emit(
      state
          .copyWith(
            actionInFlightIds: _without(state.actionInFlightIds, requestId),
          )
          .withError(deliveryError),
    );
    return;
  }

  

  final handoffResult = await _repository.confirmReturnHandoff(
    sampleCodes: sampleCodes,
  );
  if (isClosed) return;

  handoffResult.fold(
    (failure) {
      final nextItems =
          state.items.where((i) => i.requestId != requestId).toList();
      emit(
        state
            .copyWith(
              items: nextItems,
              actionInFlightIds: _without(state.actionInFlightIds, requestId),
            )
            .withError(failure.errorMessage),
      );
    },
    (message) {
      final nextItems =
          state.items.where((i) => i.requestId != requestId).toList();
      emit(
        state
            .copyWith(
              items: nextItems,
              actionInFlightIds: _without(state.actionInFlightIds, requestId),
            )
            .withSuccess(message ?? 'Delivery confirmed successfully'),
      );
    },
  );
}

  // ─────────────────────────────────────────────
  // Reject
  // ─────────────────────────────────────────────

  Future<void> onRejectTapped(
  BuildContext context,
  String requestId,
) async {
  if (state.actionInFlightIds.contains(requestId)) return;

  if (state.returnOffer && state.returnableSamples.isNotEmpty) {
    final selectedCodes = await ReturnHandoffDialog.show(
      context,
      returnableSamples: state.returnableSamples,
    );
    if (selectedCodes == null) return; // dismissed — do nothing
    await _runRejectDelivery(requestId, selectedCodes);
  } else {
    await _runRejectDelivery(requestId, const []);
  }
}

Future<void> _runRejectDelivery(
  String requestId,
  List<String> sampleCodes,
) async {
  emit(
    state.copyWith(
      actionInFlightIds: {...state.actionInFlightIds, requestId},
    ),
  );

  final result = await _repository.rejectDelivery(requestId: requestId);
  if (isClosed) return;

  final rejectError = result.fold((f) => f.errorMessage, (_) => null);
  if (rejectError != null) {
    emit(
      state
          .copyWith(
            actionInFlightIds: _without(state.actionInFlightIds, requestId),
          )
          .withError(rejectError),
    );
    return;
  }

  // ✅ Send handoff after reject too
  final handoffResult = await _repository.confirmReturnHandoff(
    sampleCodes: sampleCodes,
  );
  if (isClosed) return;

  handoffResult.fold(
    (failure) {
      final nextItems =
          state.items.where((i) => i.requestId != requestId).toList();
      emit(
        state
            .copyWith(
              items: nextItems,
              actionInFlightIds: _without(state.actionInFlightIds, requestId),
            )
            .withError(failure.errorMessage),
      );
    },
    (message) {
      final nextItems =
          state.items.where((i) => i.requestId != requestId).toList();
      emit(
        state
            .copyWith(
              items: nextItems,
              actionInFlightIds: _without(state.actionInFlightIds, requestId),
            )
            .withSuccess(message ?? 'Delivery rejected successfully'),
      );
    },
  );
}

  Set<String> _without(Set<String> set, String id) {
    return {...set}..remove(id);
  }
}