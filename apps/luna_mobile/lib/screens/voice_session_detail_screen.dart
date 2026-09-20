import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_config.dart';
import '../data/repositories/voice_call_repository.dart';
import '../features/diary/data/datasources/mock_diary_datasource.dart';
import '../features/diary/data/datasources/remote_diary_datasource.dart';
import '../features/diary/data/models/diary_entry_model.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/staggered_entrance.dart';

class VoiceSessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? sessionData;

  const VoiceSessionDetailScreen({
    super.key,
    this.sessionData,
  });

  @override
  State<VoiceSessionDetailScreen> createState() => _VoiceSessionDetailScreenState();
}

class _VoiceSessionDetailScreenState extends State<VoiceSessionDetailScreen> {
  final VoiceCallRepository _voiceCallRepo = VoiceCallRepository();
  Map<String, dynamic>? _sessionData;
  Timer? _pollingTimer;
  int _pollCount = 0;
  int _infiniteLimit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sessionData = widget.sessionData != null ? Map<String, dynamic>.from(widget.sessionData!) : null;
    _checkAndStartPolling();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 150) {
      final rawTranscript = _sessionData?['transcript'] as List? ?? [];
      if (_infiniteLimit < rawTranscript.length) {
        setState(() {
          _infiniteLimit += 10;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  bool _isTitleLoading(String title) {
    return title.isEmpty ||
        title.contains(r'$skeleton') ||
        _sessionData?['is_title_generating'] == true;
  }

  void _checkAndStartPolling() {
    final rawTitle = _sessionData?['title']?.toString() ?? '';
    if (_isTitleLoading(rawTitle)) {
      _pollCount = 0;
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
        _pollCount++;
        if (_pollCount > 8) {
          timer.cancel();
          return;
        }
        await _pollUpdatedSessionData();
      });
    }
  }

  Future<void> _pollUpdatedSessionData() async {
    final sessionId = _sessionData?['id']?.toString();
    if (sessionId != null && sessionId.isNotEmpty) {
      final updated = await _voiceCallRepo.fetchConversationById(sessionId);
      if (updated != null && mounted) {
        final newTitle = updated['title']?.toString() ?? '';
        setState(() {
          _sessionData?['title'] = newTitle;
          _sessionData?['is_title_generating'] = updated['is_title_generating'];
        });

        if (!_isTitleLoading(newTitle)) {
          _pollingTimer?.cancel();
          _pollingTimer = null;
        }
        return;
      }
    }

    final res = await _voiceCallRepo.fetchTodayVoiceSessions(page: 1, limit: 10);
    final items = (res['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (items.isNotEmpty && mounted) {
      final match = items.firstWhere(
        (it) => it['id']?.toString() == sessionId,
        orElse: () => items.first,
      );
      final newTitle = match['title']?.toString() ?? '';
      setState(() {
        _sessionData = Map<String, dynamic>.from(match);
      });
      if (!_isTitleLoading(newTitle)) {
        _pollingTimer?.cancel();
        _pollingTimer = null;
      }
    }
  }

  static Color _parseHexColor(dynamic input) {
    if (input is Color) return input;
    if (input is String) {
      String hex = input.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      final val = int.tryParse(hex, radix: 16);
      if (val != null) return Color(val);
    }
    return const Color(0xFF6C63FF);
  }

  Widget _buildTitleSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 130,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawTitle = _sessionData?['title']?.toString() ?? '';
    final bool isTitleLoading = _isTitleLoading(rawTitle);
    final displayTitle = rawTitle.replaceAll(r'$skeleton', '').trim();
    final title = displayTitle.isEmpty ? 'Sesi Panggilan Suara' : displayTitle;
    final date = _sessionData?['date']?.toString() ?? 'Hari ini, 09:15 AM';
    final duration = _sessionData?['duration']?.toString() ?? '04:12';
    
    final emotionAnalysisMap = _sessionData?['emotion_analysis'] as Map<String, dynamic>?;
    final rawEmotionList = (_sessionData?['emotions_breakdown'] ?? emotionAnalysisMap?['emotions_breakdown']) as List? ?? [
      {'label': 'Ketenangan & Kedamaian', 'emoji': '😌', 'percent': 0.85, 'color': '#4ECDC4'},
      {'label': 'Bahagia & Puas', 'emoji': '😃', 'percent': 0.60, 'color': '#FFE6A7'},
      {'label': 'Takut & Gelisah', 'emoji': '😨', 'percent': 0.25, 'color': '#6C63FF'},
      {'label': 'Tingkat Stres', 'emoji': '😟', 'percent': 0.15, 'color': '#FF8B94'},
    ];

    final emotionsBreakdown = rawEmotionList.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return {
        'label': map['label']?.toString() ?? 'Emosi',
        'emoji': map['emoji']?.toString() ?? '😊',
        'percent': (map['percent'] as num?)?.toDouble() ?? 0.5,
        'color': _parseHexColor(map['color']),
      };
    }).toList();

    final rawTranscript = _sessionData?['transcript'] as List? ?? [
      {
        'role': 'user',
        'content': 'Halo Luna, aku merasa cemas sekali dengan beban pekerjaanku hari ini.',
        'time': '09:15 AM',
        'emotionTag': 'fear (68%)',
        'emotionEmoji': '😨',
      },
      {
        'role': 'assistant',
        'content': 'Halo! Aku di sini mendengarkanmu. Ceritakan padaku apa yang membuatmu merasa cemas hari ini?',
        'time': '09:15 AM',
      },
    ];

    final transcriptList = rawTranscript.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return {
        'role': map['role']?.toString() ?? 'user',
        'content': map['content']?.toString() ?? '',
        'time': map['time']?.toString() ?? '09:15 AM',
        'emotionTag': map['emotionTag']?.toString(),
        'emotionEmoji': map['emotionEmoji']?.toString(),
      };
    }).toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF6F8FF),
              Color(0xFFEFF2FE),
              Color(0xFFF8F9FE),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Bar Navigation
              StaggeredEntrance(
                index: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Detail Sesi Suara',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Header Card: Title (with Skeleton Loading support), Date, Duration Badge
                      StaggeredEntrance(
                        index: 1,
                        child: GlassCard(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.volume_up_rounded,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: isTitleLoading
                                    ? _buildTitleSkeleton()
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$date • $duration',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 1. ANALISIS PARAMETER EMOSI (Progress Chart Section)
                      StaggeredEntrance(
                        index: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.analytics_outlined,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'ANALISIS PARAMETER EMOSI',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            GlassCard(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  ...emotionsBreakdown.map((emo) {
                                    final double pct = (emo['percent'] as double).clamp(0.0, 1.0);
                                    final int pctInt = (pct * 100).round();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 14.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(emo['emoji'].toString(), style: const TextStyle(fontSize: 16)),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    emo['label'].toString(),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '$pctInt%',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(999),
                                            child: LinearProgressIndicator(
                                              value: pct,
                                              minHeight: 8,
                                              backgroundColor: const Color(0xFFE2E4F0),
                                              valueColor: AlwaysStoppedAnimation<Color>(emo['color'] as Color),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Tombol Lihat Jurnal Harian AI (dengan State Loading vs Ready)
                      StaggeredEntrance(
                        index: 3,
                        child: SizedBox(
                          width: double.infinity,
                        child: isTitleLoading
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withAlpha(120),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Jurnal Harian Sedang Dibuat...',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () async {
                                  try {
                                    final diaryRepo = AppConfig.useMockData
                                        ? MockDiaryDataSource()
                                        : RemoteDiaryDataSource();
                                    DiaryEntryModel? entry = await diaryRepo.getTodayDiary();
                                    entry ??= await diaryRepo.generateTodayDiary();

                                    if (context.mounted) {
                                      final Map<String, dynamic> diaryArgs = entry != null
                                          ? {
                                              'id': entry.id,
                                              'title': entry.title,
                                              'date': entry.date,
                                              'sessionCount': entry.sessionCount,
                                              'lastSessionTime': entry.lastSessionTime,
                                              'moodTag': entry.moodTag,
                                              'moodEmoji': entry.moodEmoji,
                                              'summary': entry.summary,
                                              'riskWarning': entry.riskWarning != null
                                                  ? {
                                                      'detected': entry.riskWarning!.detected,
                                                      'type': entry.riskWarning!.type,
                                                      'title': entry.riskWarning!.title,
                                                      'level': entry.riskWarning!.level,
                                                      'message': entry.riskWarning!.message,
                                                    }
                                                  : null,
                                              'aiInsight': entry.aiInsight,
                                              'importantEvents': entry.importantEvents,
                                              'emotionalReflection': entry.emotionalReflection,
                                              'sessions': entry.sessions
                                                  .map((s) => {
                                                        'id': s.id,
                                                        'title': s.title,
                                                        'time': s.time,
                                                        'moodTag': s.moodTag,
                                                        'moodEmoji': s.moodEmoji,
                                                      })
                                                  .toList(),
                                            }
                                          : {
                                              'id': 'today_default',
                                              'title': 'Refleksi Harian LUNA',
                                              'date': 'Hari ini',
                                              'sessionCount': 1,
                                              'lastSessionTime': '09:15 AM',
                                              'moodTag': 'Tenang 🌿',
                                              'moodEmoji': '🌿',
                                              'summary': 'Sesi percakapan harian berhasil disintesis oleh LUNA AI.',
                                              'aiInsight': 'Pengguna merasa lebih lega setelah berdialog dengan LUNA AI.',
                                              'emotionalReflection': 'Respon emosional terpantau positif dan stabil.',
                                              'importantEvents': ['[Hari ini] Percakapan Suara LUNA AI'],
                                              'sessions': [],
                                            };

                                      Navigator.pushNamed(context, '/diary_detail', arguments: diaryArgs);
                                    }
                                  } catch (e, stack) {
                                    debugPrint('⚠️ [DIARY DETAIL NAV EXCEPTION]: $e\n$stack');
                                    if (context.mounted) {
                                      final fallbackArgs = {
                                        'id': 'today_fallback',
                                        'title': 'Jurnal Harian LUNA AI',
                                        'date': 'Hari ini',
                                        'sessionCount': 1,
                                        'lastSessionTime': 'Hari ini',
                                        'moodTag': 'Tenang 🌿',
                                        'moodEmoji': '🌿',
                                        'summary': 'Sesi percakapan harian berhasil disintesis oleh LUNA AI.',
                                        'aiInsight': 'Pengguna merasa lebih lega setelah berdialog dengan LUNA AI.',
                                        'emotionalReflection': 'Respon emosional terpantau positif dan stabil.',
                                        'importantEvents': ['[Hari ini] Sesi Percakapan Suara LUNA AI'],
                                        'sessions': [],
                                      };
                                      Navigator.pushNamed(context, '/diary_detail', arguments: fallbackArgs);
                                    }
                                  }
                                },
                                icon: const Icon(Icons.auto_awesome, size: 18),
                                label: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Lihat Jurnal Harian AI Hari Ini',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. TRANSKRIP PERCAKAPAN SUARA (Diary Style)
                      StaggeredEntrance(
                        index: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F4FB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF20667B),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'TRANSKRIP PERCAKAPAN SUARA',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF20667B),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${transcriptList.length} Pesan',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Builder(
                        builder: (context) {
                          final int totalCount = transcriptList.length;
                          final int displayCount = totalCount.clamp(0, _infiniteLimit);
                          final pageItems = transcriptList.sublist(0, displayCount);

                          return Column(
                            children: [
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pageItems.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = pageItems[index];
                                  final isUser = item['role'] == 'user' || item['isUser'].toString() == 'true';
                                  final String speakerLabel = isUser ? 'Pengguna' : 'LUNA AI';

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isUser ? const Color(0xFFF0F2FF) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isUser
                                            ? AppColors.primary.withValues(alpha: 0.25)
                                            : Colors.grey.shade200,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(6),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isUser ? AppColors.primaryContainer : const Color(0xFFE0F4FB),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    speakerLabel,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                      color: isUser ? AppColors.primary : const Color(0xFF20667B),
                                                    ),
                                                  ),
                                                ),
                                                if (isUser && item['emotionTag'] != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFFF0F0),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '${item['emotionEmoji'] ?? '😟'} ${item['emotionTag']}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: const Color(0xFFD32F2F),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              item['time'] ?? '',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item['content'] ?? item['text'] ?? '',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              if (_infiniteLimit < totalCount) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Memuat percakapan berikutnya...',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
