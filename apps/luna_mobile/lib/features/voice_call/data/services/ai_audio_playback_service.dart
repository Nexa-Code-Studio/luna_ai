import 'dart:async';
import 'dart:collection';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class QueuedAudioChunk {
  final Uint8List bytes;
  final int assistantTurnId;
  final int sequence;

  const QueuedAudioChunk({
    required this.bytes,
    required this.assistantTurnId,
    required this.sequence,
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

  final StreamController<int> _playbackCompletedController =
      StreamController<int>.broadcast();

  Stream<int> get onPlaybackCompleted => _playbackCompletedController.stream;
  bool get isPlaying => _isPlaying;
  int get currentAssistantTurnId => _currentAssistantTurnId;

  void _initPlayerListeners() {
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _playNextChunk();
    });
  }

  /// Start a new assistant turn playback context
  void prepareNewAssistantTurn(int assistantTurnId) {
    if (_currentAssistantTurnId != assistantTurnId) {
      stop();
      _currentAssistantTurnId = assistantTurnId;
      _isStreamFinished = false;
    }
  }

  /// Enqueue an incoming TTS audio byte chunk
  void enqueueChunk({
    required Uint8List bytes,
    required int assistantTurnId,
    required int sequence,
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

    try {
      _isPlaying = true;
      debugPrint('🔊 [AUDIO PLAYING CHUNK]: Turn ${nextChunk.assistantTurnId}, Seq ${nextChunk.sequence} (${nextChunk.bytes.length} bytes)');
      await _player.play(BytesSource(nextChunk.bytes));
    } catch (e) {
      debugPrint('⚠️ [AUDIO PLAY EXCEPTION]: $e');
      _isPlaying = false;
      _playNextChunk();
    }
  }

  void _notifyCompleted() {
    final finishedTurn = _currentAssistantTurnId;
    debugPrint('✅ [AUDIO PLAYBACK COMPLETED]: All audio for turn $finishedTurn finished playing.');
    _playbackCompletedController.add(finishedTurn);
  }

  /// Immediately stop playback, flush audio queue, and invalidate current assistant turn
  Future<void> stop() async {
    if (_currentAssistantTurnId > 0) {
      _cancelledTurnIds.add(_currentAssistantTurnId);
    }
    _queue.clear();
    _isPlaying = false;
    _isStreamFinished = false;

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
  }
}
