import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Plays local notification audio (not the OS notification channel).
///
/// Kept out of UI widgets: inject into [NotificationCubit] or other
/// presentation logic. Uses a single [AudioPlayer] to avoid overlapping
/// clips and duplicate native players across rebuilds.
@lazySingleton
class NotificationSoundService {
  NotificationSoundService();

  /// Short medical-style alert bundled at [defaultAssetPath].
  static const String defaultAssetPath = 'sounds/medical_alert.mp3';

  /// Optional haptic paired with the alert (no extra packages).
  /// Toggle in tests if needed.
  bool enableVibration = true;

  /// Override asset per API `status` string when you add more clips later.
  /// Keys must match backend status values exactly.
  static const Map<String, String> assetPathByStatus = {};

  AudioPlayer? _player;

  AudioPlayer get _audio {
    return _player ??= AudioPlayer(playerId: 'notification_sound');
  }

  /// Resolves which asset to play for a given [status] (extensible map).
  String resolveAssetPath({String? status}) {
    if (status == null || status.isEmpty) {
      return defaultAssetPath;
    }
    return assetPathByStatus[status] ?? defaultAssetPath;
  }

  /// Plays the new-notification sound once.
  ///
  /// Stops any in-flight playback first so rapid arrivals do not stack.
  /// [status] selects the asset when [assetPathByStatus] defines a mapping.
  Future<void> playNewNotificationSound({String? status}) async {
    final path = resolveAssetPath(status: status);
    try {
      await _audio.stop();
      await _audio.setReleaseMode(ReleaseMode.release);
      await _audio.play(AssetSource(path));
      if (enableVibration) {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {
      // Avoid crashing the poll loop if asset is missing or codec fails.
    }
  }

  /// Dispose the underlying player (e.g. tests or strict lifecycle control).
  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}
