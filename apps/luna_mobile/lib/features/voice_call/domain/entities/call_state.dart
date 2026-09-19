/// Central explicit conversation state machine for Hybrid Half-Duplex AI Call.
enum CallState {
  idle,
  listening,
  thinking,
  aiSpeaking,
  interrupting,
  ended,
  error,
}

/// Operating mode for voice interaction.
enum ConversationMode {
  hybridAuto,
  pushToTalk,
}
