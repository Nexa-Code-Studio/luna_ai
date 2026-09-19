import 'chat_datasource.dart';
import '../models/conversation_model.dart';
import '../models/chat_message_model.dart';

class MockChatDataSource implements ChatDataSource {
  final List<ConversationModel> _conversations = [
    ConversationModel(
      id: '1',
      title: 'Refleksi Harian & Evaluasi Ujian',
      date: '24 Oktober 2023',
      lastSessionTime: '21:45 PM',
      moodTag: 'Cemas & Stres',
      moodEmoji: '😰',
      summary: 'Kumulatif 3 sesi suara hari ini: Refleksi Pagi (kecemasan akademik), Curhat Sore (istirahat teh), dan Refleksi Malam (evaluasi jadwal).',
      messages: const [
        ChatMessageModel(
          id: 'm1',
          conversationId: '1',
          isUser: true,
          time: '09:15 AM',
          text: 'Saya sangat cemas dan takut tidak bisa menyelesaikan tugas kuliah ini dengan baik.',
          emotionTag: 'fear (68%)',
          emotionEmoji: '😨',
        ),
        ChatMessageModel(
          id: 'm2',
          conversationId: '1',
          isUser: false,
          time: '09:16 AM',
          text: 'Aku mendengarmu. Sangat wajar merasa cemas saat tugas menumpuk. Mari kita uraikan bersama menjadi langkah kecil ya.',
        ),
        ChatMessageModel(
          id: 'm3',
          conversationId: '1',
          isUser: true,
          time: '16:30 PM',
          text: 'Saya baru saja minum teh dan berjalan santai sebentar. Rasanya sedikit lebih lega.',
          emotionTag: 'netral (60%)',
          emotionEmoji: '😐',
        ),
        ChatMessageModel(
          id: 'm4',
          conversationId: '1',
          isUser: false,
          time: '16:31 PM',
          text: 'Itu langkah yang luar biasa! Memberikan waktu istirahat pada pikiran sangat penting untuk pemulihan energimu.',
        ),
      ],
    ),
  ];

  @override
  Future<List<ConversationModel>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_conversations);
  }

  @override
  Future<ConversationModel?> getConversationById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return _conversations.isNotEmpty ? _conversations.first : null;
    }
  }

  @override
  Future<ChatMessageModel> sendMessage(String conversationId, String text) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final userMsg = ChatMessageModel(
      id: 'm_${now.millisecondsSinceEpoch}',
      conversationId: conversationId,
      isUser: true,
      time: timeStr,
      text: text,
      emotionTag: 'calm (75%)',
      emotionEmoji: '😌',
    );

    // Append to local store if exists
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final current = _conversations[index];
      final updatedMsgs = List<ChatMessageModel>.from(current.messages)..add(userMsg);

      // Simulate AI response
      final aiMsg = ChatMessageModel(
        id: 'm_ai_${now.millisecondsSinceEpoch}',
        conversationId: conversationId,
        isUser: false,
        time: timeStr,
        text: 'Terima kasih sudah berbagi denganku. Aku selalu ada di sini untuk mendengarkan dan mendukungmu.',
      );
      updatedMsgs.add(aiMsg);

      _conversations[index] = ConversationModel(
        id: current.id,
        title: current.title,
        date: current.date,
        lastSessionTime: timeStr,
        moodTag: current.moodTag,
        moodEmoji: current.moodEmoji,
        summary: current.summary,
        messages: updatedMsgs,
      );
    }

    return userMsg;
  }
}
