import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

/// [DEPRECATED in Hybrid Half-Duplex Mode]
///
/// Under the Hybrid Half-Duplex architecture, raw microphone audio bytes
/// are NOT streamed to the backend to avoid audio hardware contention on
/// Android (which cannot reliably share the microphone hardware between raw
/// recorder and speech_to_text). STT transcription is computed locally on
/// client, and only textual transcript events and turn metadata are transmitted.
class AudioRecorderService {
  bool _isRecording = false;
  Timer? _recordSimulationTimer;

  final StreamController<Uint8List> _audioStreamController =
      StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get audioStream => _audioStreamController.stream;
  bool get isRecording => _isRecording;

  void startRecording() {
    if (_isRecording) return;
    _isRecording = true;

    final random = Random();
    // Simulate streaming 160-byte audio PCM chunks every 100ms
    _recordSimulationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isRecording) {
        final dummyPcmChunk = Uint8List.fromList(
          List.generate(160, (_) => random.nextInt(256)),
        );
        _audioStreamController.add(dummyPcmChunk);
      }
    });
  }

  void stopRecording() {
    _isRecording = false;
    _recordSimulationTimer?.cancel();
  }

  void dispose() {
    stopRecording();
    _audioStreamController.close();
  }
}
