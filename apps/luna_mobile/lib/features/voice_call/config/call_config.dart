/// Centralized configuration for Hybrid Half-Duplex voice conversation timings and flags.
class CallConfig {
  const CallConfig._();

  // Guard delays in milliseconds
  static const int sttRestartDelayMs = 200;
  static const int playbackToListeningGuardMs = 200;
  static const int bargeInGuardMs = 150;

  // Adaptive turn baseline timeouts (ms)
  static const int completeWaitMs = 650;
  static const int normalWaitMs = 900;
  static const int incompleteWaitMs = 1500;
  static const int hesitationWaitMs = 1400;
  static const int hardMaxInactivityMs = 2200;

  // Feature toggles
  static const bool autoRestartStt = true;
  static const bool manualBargeInEnabled = true;
  static const bool hybridConversationEnabled = true;
}
