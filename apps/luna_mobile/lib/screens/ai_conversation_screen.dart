import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/staggered_entrance.dart';

class AiConversationScreen extends StatefulWidget {
  const AiConversationScreen({super.key});

  @override
  State<AiConversationScreen> createState() => _AiConversationScreenState();
}

class _AiConversationScreenState extends State<AiConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  static const int _pageSize = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchConversations(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _fetchMoreConversations();
      }
    }
  }

  Future<void> _fetchConversations({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      final headers = await AppConfig.getAuthHeaders();
      final res = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/conversations?page=1&limit=$_pageSize'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        List<dynamic> items = [];
        bool hasMore = false;

        if (data is Map<String, dynamic>) {
          items = data['items'] as List? ?? [];
          if (data['pagination'] is Map) {
            hasMore = data['pagination']['has_more'] == true;
          } else if (data['has_more'] is bool) {
            hasMore = data['has_more'] as bool;
          }
        } else if (data is List) {
          items = data;
          hasMore = items.length >= _pageSize;
        }

        setState(() {
          _conversations = List<Map<String, dynamic>>.from(items);
          _hasMore = hasMore;
          _currentPage = 1;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreConversations() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    final nextPage = _currentPage + 1;

    try {
      final headers = await AppConfig.getAuthHeaders();
      final res = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/conversations?page=$nextPage&limit=$_pageSize'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        List<dynamic> items = [];
        bool hasMore = false;

        if (data is Map<String, dynamic>) {
          items = data['items'] as List? ?? [];
          if (data['pagination'] is Map) {
            hasMore = data['pagination']['has_more'] == true;
          } else if (data['has_more'] is bool) {
            hasMore = data['has_more'] as bool;
          }
        } else if (data is List) {
          items = data;
          hasMore = items.length >= _pageSize;
        }

        setState(() {
          _conversations.addAll(List<Map<String, dynamic>>.from(items));
          _currentPage = nextPage;
          _hasMore = hasMore;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  static ({String tag, String emoji}) _detectEmotionFallback(String text) {
    final tLow = text.toLowerCase();
    const anxWords = ['cemas', 'takut', 'nervous', 'panggung', 'khawatir', 'panik', 'deg-degan', 'gugup', 'takutnya', 'bingung', 'was-was', 'tegang'];
    const depWords = ['sedih', 'nangis', 'menangis', 'hampa', 'sendiri', 'kehilangan', 'terpuruk', 'putus asa', 'kecewa', 'patah hati', 'bunuh diri'];
    const strWords = ['stres', 'capek', 'lelah', 'beban', 'berat', 'penat', 'pusing', 'mumet', 'tekanan', 'tugas', 'deadline', 'kerjaan', 'letih'];
    const angWords = ['marah', 'kesal', 'jengkel', 'benci', 'emosi', 'sebal', 'kesel', 'geram', 'murka'];
    const posWords = ['lega', 'senang', 'bahagia', 'terima kasih', 'makasih', 'enakan', 'tenang', 'nyaman', 'santai', 'alhamdulillah', 'syukurlah', 'baik', 'bersyukur'];

    if (anxWords.any((w) => tLow.contains(w))) {
      return (tag: 'fear (78%)', emoji: '😨');
    }
    if (depWords.any((w) => tLow.contains(w))) {
      return (tag: 'sadness (82%)', emoji: '😔');
    }
    if (strWords.any((w) => tLow.contains(w))) {
      return (tag: 'stress (75%)', emoji: '💥');
    }
    if (angWords.any((w) => tLow.contains(w))) {
      return (tag: 'anger (70%)', emoji: '😡');
    }
    if (posWords.any((w) => tLow.contains(w))) {
      return (tag: 'calm (85%)', emoji: '😌');
    }
    return (tag: 'netral (60%)', emoji: '😐');
  }

  @override
  Widget build(BuildContext context) {

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

              // Header Bar

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),

                child: Row(

                  children: [

                    IconButton(

                      icon: const Icon(Icons.arrow_back),

                      color: AppColors.textPrimary,

                      onPressed: () {

                        Navigator.pop(context);

                      },

                    ),

                    Image.asset(

                      'assets/images/luna_logo.png',

                      width: 32,

                      height: 32,

                      fit: BoxFit.contain,

                      errorBuilder: (context, error, stackTrace) {

                        return const Icon(

                          Icons.nightlight_round,

                          size: 28,

                          color: AppColors.primary,

                        );

                      },

                    ),

                    const SizedBox(width: 8),

                    Text(

                      'Sesi Suara LUNA',

                      style: GoogleFonts.inter(

                        fontSize: 16,

                        fontWeight: FontWeight.w700,

                        color: AppColors.primary,

                      ),

                    ),

                  ],

                ),

              ),

              const Divider(height: 1, color: Color(0xFFEBECEF)),



              // Scrollable Content Body with Pull-to-Refresh & Infinite Scroll
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _fetchConversations(isRefresh: true),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(

                    children: [

                      const SizedBox(height: 12),



                      // 3D Glowing Iridescent Orb Visual
                      StaggeredEntrance(
                        index: 0,
                        child: Center(
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const SweepGradient(
                                colors: [
                                  Color(0xFFFFB6C1),
                                  Color(0xFFE2DAFF),
                                  Color(0xFFA7E6FF),
                                  Color(0xFF8B93FF),
                                  Color(0xFFFFB6C1),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white,
                                    Color(0xFFEADBFF),
                                    Color(0xFFA7E6FF),
                                  ],
                                  center: Alignment(-0.3, -0.3),
                                  radius: 0.8,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.graphic_eq,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title & Subtitle Greeting
                      StaggeredEntrance(
                        index: 1,
                        child: Column(
                          children: [
                            Text(
                              'LUNA Siap Mendengarkan',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Bicara secara alami kapan saja tanpa mengetik. LUNA hadir mendampingi dan mendengarkan perasaanmu.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Main Action Button: Mulai Sesi Suara
                      StaggeredEntrance(
                        index: 2,
                        child: CustomPillButton(
                          text: 'Mulai Sesi Suara',
                          suffixIcon: Icons.mic,
                          onPressed: () async {
                            await Navigator.pushNamed(context, '/voice_call');
                            if (mounted) {
                              _fetchConversations(isRefresh: true);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Recent Voice Sessions Section
                      StaggeredEntrance(
                        index: 3,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'RIWAYAT SESI SUARA TERAKHIR',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _isLoading
                            ? const _SessionListSkeleton(key: ValueKey('session_skeleton_list'))
                            : _conversations.isNotEmpty
                                ? Column(
                                    key: const ValueKey('session_conversation_list'),
                                    children: [
                                      for (int i = 0; i < _conversations.length; i++)
                                        _AnimatedSessionCard(
                                          key: ValueKey('session_card_${_conversations[i]['id'] ?? i}'),
                                          index: i,
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 10),
                                            child: _buildSessionCard(context, _conversations[i]),
                                          ),
                                        ),
                                      if (_isLoadingMore)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 16.0),
                                          child: Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (!_hasMore && _conversations.length >= _pageSize)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                                          child: Center(
                                            child: Text(
                                              'Semua riwayat telah dimuat',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : Padding(
                                    key: const ValueKey('session_empty_list'),
                                    padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.forum_outlined, size: 44, color: AppColors.textLight),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Belum ada riwayat sesi suara',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Mulai panggilan suara bersama LUNA untuk menyimpan sesi percakapanmu.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: AppColors.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            ],

          ),

        ),

      ),

    );

  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> conv) {
    final title = conv['title']?.toString() ?? 'Sesi Percakapan LUNA';
    final time = conv['lastMessageTime']?.toString() ?? 'Hari ini';
    final msgs = conv['messages'] as List? ?? [];
    final duration = (conv['duration'] != null && conv['duration'].toString().isNotEmpty)
        ? conv['duration'].toString()
        : '00:00';

    String dominantEmoji = conv['dominant_emoji']?.toString() ?? '';
    String dominantEmotion = conv['dominant_emotion']?.toString() ?? '';
    if (dominantEmoji.isEmpty) {
      for (final m in msgs) {
        if (m is Map && m['sender'] == 'user') {
          final emoji = (m['emotionEmoji'] ?? m['emotion_emoji'])?.toString();
          if (emoji != null && emoji.isNotEmpty) {
            dominantEmoji = emoji;
            break;
          }
          final text = (m['text'] ?? '').toString();
          if (text.isNotEmpty) {
            dominantEmoji = _detectEmotionFallback(text).emoji;
            break;
          }
        }
      }
    }
    if (dominantEmoji.isEmpty) dominantEmoji = '😌';
    if (dominantEmotion.isEmpty) dominantEmotion = 'Tenang & Nyaman';

    return _buildSessionHistoryCard(
      title: title,
      duration: duration,
      date: time,
      dominantEmoji: dominantEmoji,
      onTap: () {
        Navigator.pushNamed(
          context,
          '/diary_detail',
          arguments: {
            'id': conv['id'],
            'conversationId': conv['id'],
            'title': title,
            'date': time,
            'isSingleSession': true,
            'sessionCount': 1,
            'lastSessionTime': time,
            'moodTag': dominantEmotion,
            'moodEmoji': dominantEmoji,
            'summary': conv['summary'],
            'riskWarning': {'detected': false},
            'aiInsight': conv['summary'] ??
                'Percakapan berhasil disintesis dan diproses untuk pemantauan kesehatan emosionalmu.',
            'importantEvents': ['Sesi percakapan aktif selesai tercatat'],
            'emotionalReflection':
                'Emosi terartikulasi secara positif melalui sesi curhat bersama AI.',
            'sessions': [
              {
                'id': conv['id'] ?? 's1',
                'title': title,
                'time': time,
                'moodTag': dominantEmotion,
                'moodEmoji': dominantEmoji,
                'emotionsBreakdown': [
                  {
                    'name': 'netral',
                    'label': 'Netral',
                    'emoji': '😐',
                    'percent': 0.60,
                    'color': const Color(0xFFA7E6FF)
                  },
                  {
                    'name': 'happy',
                    'label': 'Lega',
                    'emoji': '😌',
                    'percent': 0.40,
                    'color': const Color(0xFFFFE6A7)
                  },
                ],
                'transcripts': msgs
                    .map((m) {
                      final isUser = m['sender'] == 'user';
                      final text = (m['text'] ?? '').toString();
                      final tag = (m['emotionTag'] ?? m['emotion_tag'])?.toString();
                      final emoji = (m['emotionEmoji'] ?? m['emotion_emoji'])?.toString();

                      String resolvedTag = '';
                      String resolvedEmoji = '';
                      if (isUser) {
                        if (tag != null && tag.isNotEmpty && tag != 'Refleksi') {
                          resolvedTag = tag;
                          resolvedEmoji = (emoji != null && emoji.isNotEmpty) ? emoji : '🌱';
                        } else {
                          final fallback = _detectEmotionFallback(text);
                          resolvedTag = fallback.tag;
                          resolvedEmoji = fallback.emoji;
                        }
                      }

                      return {
                        'isUser': isUser,
                        'time': m['time'] ?? '',
                        'text': text,
                        'emotionTag': resolvedTag,
                        'emotionEmoji': resolvedEmoji,
                      };
                    })
                    .toList(),
              }
            ],
            'selectedSessionId': conv['id'] ?? 's1',
          },
        );
      },
    );
  }

  Widget _buildSessionHistoryCard({
    required String title,
    required String duration,
    required String date,
    required String dominantEmoji,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      width: double.infinity,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              dominantEmoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$date • $duration',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textLight,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _SessionListSkeleton extends StatefulWidget {
  const _SessionListSkeleton({super.key});

  @override
  State<_SessionListSkeleton> createState() => _SessionListSkeletonState();
}

class _SessionListSkeletonState extends State<_SessionListSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const List<double> _titleWidthFactors = [
    0.65,
    0.50,
    0.72,
    0.58,
    0.62,
    0.54,
    0.68,
    0.48,
    0.70,
    0.56,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return Column(
          children: List.generate(10, (index) {
            final titleWidth = _titleWidthFactors[index % _titleWidthFactors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: opacity * 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: titleWidth,
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary.withValues(alpha: opacity * 0.16),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FractionallySizedBox(
                            widthFactor: 0.35,
                            child: Container(
                              height: 11,
                              decoration: BoxDecoration(
                                color: AppColors.textLight.withValues(alpha: opacity * 0.14),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withValues(alpha: opacity * 0.14),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _AnimatedSessionCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedSessionCard({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedSessionCard> createState() => _AnimatedSessionCardState();
}

class _AnimatedSessionCardState extends State<_AnimatedSessionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    final delayMs = (widget.index % 10).clamp(0, 6) * 35;
    if (delayMs == 0) {
      _animController.forward();
    } else {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _animController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}


