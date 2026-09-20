import 'dart:async';
import 'dart:collection';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../config/call_config.dart';

class QueuedAudioChunk {
  final Uint8List bytes;
  final int assistantTurnId;
  final int sequence;
  final List<double> envelope;

  const QueuedAudioChunk({
    required this.bytes,
    required this.assistantTurnId,
    required this.sequence,
    this.envelope = const [],
  });
}

/// Service managing sequential audio chunk queueing, playback, and instant cancellation.
class AiAudioPlaybackService {
  final AudioPlayer _player;

  AiAudioPlaybackService({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _initPlayerListeners();
  }

  final Queue<QueuedAudioChunk> _queue = Queue<QueuedAudioChunk>();
  final Set<int> _cancelledTurnIds = <int>{};

  int _currentAssistantTurnId = 0;
  bool _isPlaying = false;
  bool _isStreamFinished = false;
  DateTime? _lastChunkCompletedAt;

  final StreamController<int> _playbackCompletedController =
      StreamController<int>.broadcast();
  final StreamController<double> _soundLevelController =
      StreamController<double>.broadcast();

  Stream<int> get onPlaybackCompleted => _playbackCompletedController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;
  bool get isPlaying => _isPlaying;
  int get currentAssistantTurnId => _currentAssistantTurnId;

  Timer? _envelopeTimer;
  final Stopwatch _playbackStopwatch = Stopwatch();

  void _initPlayerListeners() {
    _player.onPlayerComplete.listen((_) async {
      _stopEnvelopeTicker();
      _isPlaying = false;
      _lastChunkCompletedAt = DateTime.now();

      // Tunggu jeda alami antar-kalimat sebelum memainkan chunk berikutnya
      if (_queue.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: CallConfig.interChunkPauseMs));
      }

      if (!_cancelledTurnIds.contains(_currentAssistantTurnId)) {
        _playNextChunk();
      }
    });
  }

  /// Start a new assistant turn playback context
  void prepareNewAssistantTurn(int assistantTurnId) {
    if (_currentAssistantTurnId != assistantTurnId) {
      stop();
      _currentAssistantTurnId = assistantTurnId;
      _isStreamFinished = false;
      _lastChunkCompletedAt = null;
    }
  }

  /// Enqueue an incoming TTS audio byte chunk with its time-aligned speech envelope
  void enqueueChunk({
    required Uint8List bytes,
    required int assistantTurnId,
    required int sequence,
    List<double> envelope = const [],
  }) {
    // Drop if turn has been cancelled or belongs to older assistant turn
    if (_cancelledTurnIds.contains(assistantTurnId) || assistantTurnId < _currentAssistantTurnId) {
      debugPrint('⚡ [AUDIO PLAYBACK DISCARDED]: Dropping chunk for cancelled/stale turn $assistantTurnId');
      return;
    }

    _currentAssistantTurnId = assistantTurnId;
    _queue.add(QueuedAudioChunk(
      bytes: bytes,
      assistantTurnId: assistantTurnId,
      sequence: sequence,
      envelope: envelope,
    ));

    if (!_isPlaying) {
      _playNextChunk();
    }
  }

  /// Mark that backend finished streaming all TTS chunks for this assistant turn
  void markStreamFinished(int assistantTurnId) {
    if (assistantTurnId == _currentAssistantTurnId) {
      _isStreamFinished = true;
      if (!_isPlaying && _queue.isEmpty) {
        _notifyCompleted();
      }
    }
  }

  Future<void> _playNextChunk() async {
    if (_queue.isEmpty) {
      _isPlaying = false;
      if (_isStreamFinished) {
        _notifyCompleted();
      }
      return;
    }

    final nextChunk = _queue.removeFirst();

    // Check cancellation once more before playing
    if (_cancelledTurnIds.contains(nextChunk.assistantTurnId)) {
      _playNextChunk();
      return;
    }

    // Pastikan jeda minimal antar kalimat jika chunk baru tiba terlambat
    if (_lastChunkCompletedAt != null) {
      final elapsed = DateTime.now().difference(_lastChunkCompletedAt!).inMilliseconds;
      if (elapsed < CallConfig.interChunkPauseMs) {
        await Future.delayed(Duration(milliseconds: CallConfig.interChunkPauseMs - elapsed));
        if (_cancelledTurnIds.contains(nextChunk.assistantTurnId)) {
          return;
        }
      }
    }

    try {
      _isPlaying = true;
      debugPrint('🔊 [AUDIO PLAYING CHUNK]: Turn ${nextChunk.assistantTurnId}, Seq ${nextChunk.sequence} (${nextChunk.bytes.length} bytes, ${nextChunk.envelope.length} env points)');
      _playbackStopwatch.reset();
      _playbackStopwatch.start();
      _startEnvelopeTicker(nextChunk.envelope);

      await _player.play(BytesSource(nextChunk.bytes));
    } catch (e) {
      debugPrint('⚠️ [AUDIO PLAY EXCEPTION]: $e');
      _stopEnvelopeTicker();
      _isPlaying = false;
      _playNextChunk();
    }
  }

  void _startEnvelopeTicker(List<double> envelope) {
    _envelopeTimer?.cancel();
    if (envelope.isEmpty) {
      _envelopeTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
        if (!_isPlaying) {
          _stopEnvelopeTicker();
          return;
        }
        if (!_soundLevelController.isClosed) {
          _soundLevelController.add(0.25);
        }
      });
      return;
    }

    _envelopeTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_isPlaying) {
        _stopEnvelopeTicker();
        return;
      }
      final elapsedMs = _playbackStopwatch.elapsedMilliseconds;
      // 50ms per envelope sample point
      final double sampleIndex = elapsedMs / 50.0;
      final int baseIdx = sampleIndex.floor();

      if (baseIdx < envelope.length) {
        final double frac = sampleIndex - baseIdx;
        final double v1 = envelope[baseIdx];
        final double v2 = (baseIdx + 1 < envelope.length) ? envelope[baseIdx + 1] : 0.0;
        final double level = v1 + (v2 - v1) * frac;
        if (!_soundLevelController.isClosed) {
          _soundLevelController.add(level.clamp(0.0, 1.0));
        }
      } else {
        if (!_soundLevelController.isClosed) {
          _soundLevelController.add(0.0);
        }
      }
    });
  }

  void _stopEnvelopeTicker() {
    _envelopeTimer?.cancel();
    _envelopeTimer = null;
    _playbackStopwatch.stop();
    if (!_soundLevelController.isClosed) {
      _soundLevelController.add(0.0);
    }
  }

  void _notifyCompleted() {
    final finishedTurn = _currentAssistantTurnId;
    debugPrint('✅ [AUDIO PLAYBACK COMPLETED]: All audio for turn $finishedTurn finished playing.');
    if (!_playbackCompletedController.isClosed) {
      _playbackCompletedController.add(finishedTurn);
    }
  }

  /// Immediately stop playback, flush audio queue, and invalidate current assistant turn
  Future<void> stop() async {
    _stopEnvelopeTicker();
    if (_currentAssistantTurnId > 0) {
      _cancelledTurnIds.add(_currentAssistantTurnId);
    }
    _queue.clear();
    _isPlaying = false;
    _isStreamFinished = false;
    _lastChunkCompletedAt = null;

    try {
      await _player.stop();
    } catch (e) {
      debugPrint('⚠️ [AUDIO STOP EXCEPTION]: $e');
    }
  }

  void clearQueue() {
    _queue.clear();
  }

  void dispose() {
    stop();
    _player.dispose();
    _playbackCompletedController.close();
    _soundLevelController.close();
  }
}
