import '../../domain/entities/call_state.dart';

class AiCallViewState {
  final CallState callState;
  final ConversationMode conversationMode;
  final String callId;
  final int userTurnId;
  final int activeSttSessionId;
  final int assistantTurnId;
  final String currentTranscript;
  final String latestPartial;
  final String aiTranscript;
  final double soundLevel;
  final int callDurationSeconds;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isUserSpeaking;
  final String? errorMessage;
  final String? crisisHotline;
  final String? crisisHotlineUrl;
  final bool isCrisisSession;

  const AiCallViewState({
    this.callState = CallState.idle,
    this.conversationMode = ConversationMode.hybridAuto,
    this.callId = '',
    this.userTurnId = 1,
    this.activeSttSessionId = 0,
    this.assistantTurnId = 0,
    this.currentTranscript = '',
    this.latestPartial = '',
    this.aiTranscript = '',
    this.soundLevel = 0.05,
    this.callDurationSeconds = 0,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.isUserSpeaking = false,
    this.errorMessage,
    this.crisisHotline,
    this.crisisHotlineUrl,
    this.isCrisisSession = false,
  });

  AiCallViewState copyWith({
    CallState? callState,
    ConversationMode? conversationMode,
    String? callId,
    int? userTurnId,
    int? activeSttSessionId,
    int? assistantTurnId,
    String? currentTranscript,
    String? latestPartial,
    String? aiTranscript,
    double? soundLevel,
    int? callDurationSeconds,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isUserSpeaking,
    String? errorMessage,
    String? crisisHotline,
    String? crisisHotlineUrl,
    bool? isCrisisSession,
    bool clearCrisis = false,
    bool clearError = false,
  }) {
    return AiCallViewState(
      callState: callState ?? this.callState,
      conversationMode: conversationMode ?? this.conversationMode,
      callId: callId ?? this.callId,
      userTurnId: userTurnId ?? this.userTurnId,
      activeSttSessionId: activeSttSessionId ?? this.activeSttSessionId,
      assistantTurnId: assistantTurnId ?? this.assistantTurnId,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      latestPartial: latestPartial ?? this.latestPartial,
      aiTranscript: aiTranscript ?? this.aiTranscript,
      soundLevel: soundLevel ?? this.soundLevel,
      callDurationSeconds: callDurationSeconds ?? this.callDurationSeconds,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isUserSpeaking: isUserSpeaking ?? this.isUserSpeaking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      crisisHotline: clearCrisis ? null : (crisisHotline ?? this.crisisHotline),
      crisisHotlineUrl: clearCrisis ? null : (crisisHotlineUrl ?? this.crisisHotlineUrl),
      isCrisisSession: clearCrisis ? false : (isCrisisSession ?? this.isCrisisSession),
    );
  }
}
