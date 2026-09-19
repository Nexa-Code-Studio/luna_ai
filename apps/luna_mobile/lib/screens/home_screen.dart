import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/daily_progress_local_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String _userName = 'Sahabat LUNA';
  int _todayConversationsCount = 0;
  bool _hasTodayDiary = false;
  String _moodTag = 'Tenang & Nyaman 🌿';
  String _aiInsight =
      'Setiap perasaan yang kamu alami hari ini adalah valid. Luangkan waktu sejenak untuk menarik napas dalam dan menyayangi dirimu sendiri.';

  DailyProgressData _localProgress = const DailyProgressData(date: '');
  String _targetCondition = 'general';
  String _conditionLabel = 'Fokus: Relaksasi & Perawatan Diri';
  String _conditionReason = 'Menjaga ritme emosi dan ketenangan pikiran harian';
  Map<String, dynamic>? _todayActivity;

  static final List<Map<String, dynamic>> _defaultRecommendations = [
    {
      'id': '1',
      'title': 'Latihan Pernapasan 4-7-8',
      'category': 'Mindfulness',
      'targetCondition': 'stress',
      'duration': '3 menit',
      'difficulty': 'Pemula',
      'description':
          'Tarik napas dalam 4 detik, tahan 7 detik, lalu hembuskan perlahan 8 detik untuk meredakan ketegangan sistem saraf.',
      'instructions': [
        'Duduk dengan nyaman dan punggung tegak.',
        'Tarik napas perlahan melalui hidung selama 4 detik.',
        'Tahan napasmu selama 7 detik.',
        'Hembuskan napas secara perlahan melalui mulut selama 8 detik.',
        'Ulangi siklus ini sebanyak 4 kali putaran.',
      ],
      'rationale':
          'Mengaktifkan respons relaksasi parasimpatik untuk menurunkan detak jantung dan meredakan ketegangan.',
      'isCompleted': false,
    },
    {
      'id': '2',
      'title': 'Teknik Grounding 5-4-3-2-1',
      'category': 'CBT',
      'targetCondition': 'anxiety',
      'duration': '5 menit',
      'difficulty': 'Pemula',
      'description':
          'Sadarilah 5 hal yang kamu lihat, 4 hal yang kamu sentuh, 3 suara di sekitarmu, 2 aroma, dan 1 rasa untuk kembali ke saat ini.',
      'instructions': [
        'Sebutkan 5 hal yang bisa kamu lihat di sekitarmu.',
        'Sentuh dan rasakan 4 benda yang ada di dekatmu.',
        'Dengarkan secara saksama 3 suara berbeda di ruangan ini.',
        'Identifikasi 2 aroma yang tercium olehmu saat ini.',
        'Fokuskan lidahmu pada 1 rasa yang masih tertinggal di mulutmu.',
      ],
      'rationale':
          'Mengalihkan fokus otak dari lingkaran kecemasan ke persepsi sensorik nyata saat ini.',
      'isCompleted': false,
    },
    {
      'id': '3',
      'title': 'Catatan Syukur Harian',
      'category': 'Refleksi',
      'targetCondition': 'depression',
      'duration': '3 menit',
      'difficulty': 'Pemula',
      'description':
          'Tuliskan satu hal sederhana yang memberimu kehangatan atau kenyamanan hari ini.',
      'instructions': [
        'Tarik napas dalam sejenak dan pejamkan matamu perlahan.',
        'Ingat satu momen kecil yang membuatmu merasa hangat atau tersenyum hari ini.',
        'Tuliskan secara spesifik apa momen itu dan mengapa itu berarti bagimu.',
      ],
      'rationale':
          'Melatih otak mengenali afek positif dan memutus kecenderungan bias negatif.',
      'isCompleted': false,
    },
  ];

  late List<Map<String, dynamic>> _recommendations;

  @override
  void initState() {
    super.initState();
    _recommendations = List<Map<String, dynamic>>.from(
      _defaultRecommendations.map((item) => Map<String, dynamic>.from(item)),
    );
    _loadHomeScreenData();
  }

  void refresh() => _loadHomeScreenData();

  Future<void> _loadHomeScreenData() async {
    // 1. Load cached user info first for instant display
    final cachedName = await AppConfig.getUserName();
    if (cachedName != null && cachedName.isNotEmpty && mounted) {
      setState(() => _userName = cachedName);
    }

    // 2. Load today's local self-care progress (auto-reset if new day)
    final localData = await DailyProgressLocalService.loadTodayProgress();
    if (mounted) {
      setState(() => _localProgress = localData);
    }

    if (AppConfig.useMockData) {
      if (mounted) {
        setState(() {
          for (var r in _recommendations) {
            final rId = r['id']?.toString() ?? '';
            if (_localProgress.isActivityCompleted(rId)) {
              r['isCompleted'] = true;
            }
          }
          if (_recommendations.isNotEmpty) {
            _todayActivity = _recommendations.first;
          }
        });
      }
      return;
    }

    try {
      final headers = await AppConfig.getAuthHeaders();

      // Parallel fetch across all relevant mental health endpoints
      final results = await Future.wait([
        // 0: Profile
        http
            .get(Uri.parse('${AppConfig.baseUrl}/auth/me'), headers: headers)
            .timeout(const Duration(seconds: 4))
            .catchError((_) => http.Response('{}', 500)),
        // 1: Today conversations
        http
            .get(
              Uri.parse('${AppConfig.baseUrl}/conversations/today'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 4))
            .catchError((_) => http.Response('{}', 500)),
        // 2: Today diary & emotions
        http
            .get(Uri.parse('${AppConfig.baseUrl}/diaries/today'), headers: headers)
            .timeout(const Duration(seconds: 4))
            .catchError((_) => http.Response('{}', 500)),
        // 3: Tailored recommendation for today
        http
            .get(
              Uri.parse('${AppConfig.baseUrl}/recommendations/today'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 4))
            .catchError((_) => http.Response('{}', 500)),
      ]);

      if (!mounted) return;

      // Handle Profile
      final resProfile = results[0];
      if (resProfile.statusCode == 200) {
        final data = jsonDecode(resProfile.body) as Map<String, dynamic>;
        final name = data['name']?.toString() ?? _userName;
        _userName = name;
        await AppConfig.setUserInfo(
          name: name,
          email: data['email']?.toString() ?? '',
        );
      }

      // Handle Today Conversations
      final resConversations = results[1];
      if (resConversations.statusCode == 200) {
        final data = jsonDecode(resConversations.body);
        if (data is Map<String, dynamic>) {
          _todayConversationsCount =
              data['total'] ?? (data['items'] as List?)?.length ?? 0;
          if (_todayConversationsCount > 0) {
            _localProgress = await DailyProgressLocalService.recordConversationCheckin(
              hasConversation: true,
            );
          }
          if (data['mood_tag'] != null &&
              data['mood_tag'].toString().trim().isNotEmpty) {
            _moodTag = data['mood_tag'].toString();
          }
          if (data['ai_insight'] != null &&
              data['ai_insight'].toString().trim().isNotEmpty) {
            _aiInsight = data['ai_insight'].toString();
          }
        }
      }

      // Handle Today Diary
      final resDiary = results[2];
      if (resDiary.statusCode == 200) {
        final data = jsonDecode(resDiary.body);
        if (data is Map<String, dynamic> && data['id'] != null) {
          _hasTodayDiary = true;
          _localProgress = await DailyProgressLocalService.recordDiaryCheckin(
            hasDiary: true,
          );
          if (data['moodTag'] != null &&
              data['moodTag'].toString().trim().isNotEmpty) {
            _moodTag = data['moodTag'].toString();
          }
          if (data['aiInsight'] != null &&
              data['aiInsight'].toString().trim().isNotEmpty) {
            _aiInsight = data['aiInsight'].toString();
          }
        }
      }

      // Handle Today Tailored Recommendation
      final resRecs = results[3];
      if (resRecs.statusCode == 200) {
        final dynamic data = jsonDecode(resRecs.body);
        if (data is Map<String, dynamic> && data['todayActivity'] != null) {
          _targetCondition = data['targetCondition']?.toString() ?? 'general';
          _conditionLabel =
              data['conditionLabel']?.toString() ?? 'Fokus: Relaksasi & Perawatan Diri';
          _conditionReason = data['conditionReason']?.toString() ?? '';

          final act = data['todayActivity'] as Map<String, dynamic>;
          final actId = act['id']?.toString() ?? '';
          final bool isActDone = act['isCompleted'] == true ||
              _localProgress.isActivityCompleted(actId);

          final actMap = {
            'id': actId,
            'title': act['title']?.toString() ?? 'Latihan Relaksasi',
            'category': act['category']?.toString() ?? 'Self-Care',
            'targetCondition':
                act['targetCondition']?.toString() ?? _targetCondition,
            'duration': act['duration']?.toString() ?? '5 menit',
            'difficulty': act['difficulty']?.toString() ?? 'Pemula',
            'description': act['description']?.toString() ?? '',
            'instructions': act['instructions'] is List
                ? List<String>.from(
                    act['instructions'].map((e) => e.toString()))
                : <String>[],
            'rationale': act['rationale']?.toString() ?? '',
            'iconName': act['iconName']?.toString() ?? 'spa',
            'isCompleted': isActDone,
          };

          _todayActivity = actMap;

          final List<Map<String, dynamic>> combined = [actMap];
          if (data['alternatives'] is List) {
            for (var item in data['alternatives']) {
              final altId = item['id']?.toString() ?? '';
              combined.add({
                'id': altId,
                'title': item['title']?.toString() ?? 'Rekomendasi',
                'category': item['category']?.toString() ?? 'Self-Care',
                'targetCondition':
                    item['targetCondition']?.toString() ?? _targetCondition,
                'duration': item['duration']?.toString() ?? '5 menit',
                'difficulty': item['difficulty']?.toString() ?? 'Pemula',
                'description': item['description']?.toString() ?? '',
                'instructions': <String>[],
                'rationale': '',
                'isCompleted': item['isCompleted'] == true ||
                    _localProgress.isActivityCompleted(altId),
              });
            }
          }
          _recommendations = combined;

          if (isActDone && !_localProgress.isActivityCompleted(actId)) {
            _localProgress =
                await DailyProgressLocalService.recordActivityCompletion(
              actId,
              true,
            );
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> _toggleRecommendationComplete(String id) async {
    bool currentStatus = false;
    final idx = _recommendations.indexWhere((r) => r['id'] == id);
    if (idx != -1) {
      currentStatus = _recommendations[idx]['isCompleted'] == true;
      setState(() {
        _recommendations[idx]['isCompleted'] = !currentStatus;
      });
    }

    if (_todayActivity != null && _todayActivity!['id'] == id) {
      currentStatus = _todayActivity!['isCompleted'] == true;
      setState(() {
        _todayActivity!['isCompleted'] = !currentStatus;
      });
    }

    final newStatus = !currentStatus;

    final updatedProgress =
        await DailyProgressLocalService.recordActivityCompletion(
      id,
      newStatus,
    );
    if (mounted) {
      setState(() {
        _localProgress = updatedProgress;
      });
    }

    if (!AppConfig.useMockData && newStatus) {
      try {
        final headers = await AppConfig.getAuthHeaders();
        await http
            .post(
              Uri.parse('${AppConfig.baseUrl}/recommendations/$id/complete'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
  }

  int get _completedRoutinesCount {
    int count = 0;
    if (_localProgress.hasConversation || _todayConversationsCount > 0) count++;
    if (_localProgress.hasDiary || _hasTodayDiary) count++;
    final bool activityDone = _localProgress.completedActivityIds.isNotEmpty ||
        (_todayActivity != null && _todayActivity!['isCompleted'] == true) ||
        _recommendations.any((r) => r['isCompleted'] == true);
    if (activityDone) count++;
    return count;
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
              // Header Bar with Logo and Settings Action
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  children: [
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
                      'LUNA',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      color: AppColors.primary,
                      tooltip: 'Pengaturan Profil',
                      onPressed: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                  ],
                ),
              ),

              // Scrollable Body Content
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadHomeScreenData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 110.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Greeting Header
                        Text(
                          'Halo, $_userName! 👋',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bagaimana perasaanmu hari ini?',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Empathetic AI Psychologist Insight Card
                        _buildLunaInsightCard(),
                        const SizedBox(height: 20),

                        // Quick Navigation Shortcuts
                        _buildQuickActionShortcuts(),
                        const SizedBox(height: 24),

                        // Evidence-Based Daily Progress Section (3 Pillars)
                        _buildDailyProgressSection(),
                        const SizedBox(height: 24),

                        // Latest Clinically-Informed Recommendation
                        _buildLatestRecommendationSection(),
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

  // --------------------------------------------------------------------------
  // 1. Empathetic Psychological Insight Card from Luna
  // --------------------------------------------------------------------------
  Widget _buildLunaInsightCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEDE9FE),
            Color(0xFFF3E8FF),
            Color(0xFFE0E7FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CATATAN DARI LUNA',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              // Mood Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  _moodTag,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"$_aiInsight"',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333878),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. Quick Action Shortcuts
  // --------------------------------------------------------------------------
  Widget _buildQuickActionShortcuts() {
    return Column(
      children: [
        _buildQuickCard(
          icon: Icons.chat_bubble_outline,
          iconBg: const Color(0xFF5358CB),
          iconColor: Colors.white,
          title: 'Curhat ke LUNA',
          subtitle: 'Mulai dialog suara atau teks',
          badgeText: _todayConversationsCount > 0
              ? '$_todayConversationsCount Sesi'
              : 'Siap Mendengar',
          onTap: () {
            Navigator.pushNamed(context, '/chat');
          },
        ),
        const SizedBox(height: 12),
        _buildQuickCard(
          icon: Icons.menu_book_outlined,
          iconBg: const Color(0xFFE2DAFF),
          iconColor: const Color(0xFF5358CB),
          title: 'Jurnal Refleksi AI',
          subtitle: 'Lihat rangkuman emosi harimu',
          badgeText: _hasTodayDiary ? 'Tersintesis 🌿' : 'Otomatis',
          onTap: () {
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(1);
            } else {
              Navigator.pushNamed(context, '/diary');
            }
          },
        ),
        const SizedBox(height: 12),
        _buildQuickCard(
          icon: Icons.psychology_outlined,
          iconBg: const Color(0xFFE0F4FB),
          iconColor: const Color(0xFF20667B),
          title: 'Ritem Emosional',
          subtitle: 'Pantau grafik kesehatan mental',
          badgeText: 'DASS-21',
          onTap: () {
            if (widget.onNavigateTab != null) {
              widget.onNavigateTab!(2);
            } else {
              Navigator.pushNamed(context, '/monitoring');
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      width: double.infinity,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textLight,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 3. Evidence-Based Daily Progress Section (3 Pillars)
  // --------------------------------------------------------------------------
  Widget _buildDailyProgressSection() {
    final completed = _completedRoutinesCount;
    final progressFraction = (completed / 3.0).clamp(0.0, 1.0);

    String progressMotivation;
    if (completed == 3) {
      progressMotivation =
          'Target harian tercapai! Kamu luar biasa merawat dirimu hari ini 🌟';
    } else if (completed == 2) {
      progressMotivation =
          'Tinggal 1 langkah lagi untuk melengkapi rutinitas terapeutikmu.';
    } else if (completed == 1) {
      progressMotivation =
          'Kemajuan yang sangat baik! Terus jaga ritme emosionalmu.';
    } else {
      progressMotivation =
          'Mulai harimu dengan satu langkah kecil bersama LUNA.';
    }

    final bool isConversationDone =
        _localProgress.hasConversation || _todayConversationsCount > 0;
    final bool isDiaryDone = _localProgress.hasDiary || _hasTodayDiary;
    final bool isExerciseDone =
        _localProgress.completedActivityIds.isNotEmpty ||
            (_todayActivity != null &&
                _todayActivity!['isCompleted'] == true) ||
            _recommendations.any((r) => r['isCompleted'] == true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progres Perawatan Diri',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: completed == 3
                    ? const Color(0xFFD1FAE5)
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$completed / 3 Selesai',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: completed == 3
                      ? const Color(0xFF047857)
                      : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Progress Bar & Motivation Box
        GlassCard(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completed == 3
                        ? const Color(0xFF10B981)
                        : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                progressMotivation,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),

              // Routine 1: Sesi Curhat / Dialog Emosi
              _buildProgressCheckItem(
                title: 'Sesi Curhat Bersama Luna',
                subtitle: isConversationDone
                    ? '$_todayConversationsCount sesi dialog telah tercatat hari ini'
                    : 'Ekspresikan perasaanmu lewat suara atau teks',
                icon: Icons.chat_bubble_outline,
                isCompleted: isConversationDone,
                onTap: () => Navigator.pushNamed(context, '/chat'),
              ),
              const Divider(height: 20, thickness: 0.5),

              // Routine 2: Refleksi Jurnal AI
              _buildProgressCheckItem(
                title: 'Refleksi Jurnal Harian',
                subtitle: isDiaryDone
                    ? 'Jurnal & analisis emosi telah disintesis'
                    : 'Baca rangkuman & pola emosimu hari ini',
                icon: Icons.menu_book_outlined,
                isCompleted: isDiaryDone,
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1);
                  } else {
                    Navigator.pushNamed(context, '/diary');
                  }
                },
              ),
              const Divider(height: 20, thickness: 0.5),

              // Routine 3: Latihan Koping Terpandu
              _buildProgressCheckItem(
                title: 'Latihan Relaksasi & Koping',
                subtitle: isExerciseDone
                    ? '1 latihan koping mandiri telah diselesaikan'
                    : 'Coba 1 teknik pernapasan atau mindfulness',
                icon: Icons.spa_outlined,
                isCompleted: isExerciseDone,
                onTap: () => Navigator.pushNamed(context, '/recommendation'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCheckItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            // Checkmark Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : Colors.white.withValues(alpha: 0.9),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Icon(icon, size: 14, color: AppColors.textLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? AppColors.textPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4. Tailored Daily Recommendation Container
  // --------------------------------------------------------------------------
  Widget _buildLatestRecommendationSection() {
    Map<String, dynamic> activeRec = (_todayActivity != null &&
            _todayActivity!['isCompleted'] != true)
        ? _todayActivity!
        : (_recommendations.isNotEmpty
            ? _recommendations.firstWhere(
                (r) => r['isCompleted'] != true,
                orElse: () => _todayActivity ?? _recommendations.first,
              )
            : _defaultRecommendations.first);

    final id = activeRec['id']?.toString() ?? '1';
    final isDone = activeRec['isCompleted'] == true ||
        _localProgress.isActivityCompleted(id);
    final category = activeRec['category']?.toString() ?? 'Self-Care';
    final duration = activeRec['duration']?.toString() ?? '5 menit';
    final difficulty = activeRec['difficulty']?.toString() ?? 'Pemula';
    final title = activeRec['title']?.toString() ?? 'Latihan Relaksasi';
    final description = activeRec['description']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aktivitas Pilihan Hari Ini',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await Navigator.pushNamed(context, '/recommendation');
                _loadHomeScreenData();
              },
              child: Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'Disesuaikan dengan kondisi emosional terkinimu',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Single Recommendation Container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5B61D6),
                Color(0xFF7A70EC),
                Color(0xFF9D84F5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B61D6).withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Condition Focus Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.track_changes,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _conditionLabel.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Category, Duration & Difficulty Tags Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Category Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Duration Pill
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              duration,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  $difficulty',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    // Quick Toggle Complete Button
                    GestureDetector(
                      onTap: () => _toggleRecommendationComplete(id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF10B981)
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDone
                                ? const Color(0xFF10B981)
                                : Colors.white.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDone
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isDone ? 'Selesai' : 'Tandai Selesai',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),

                // Start Practice Button CTA
                GestureDetector(
                  onTap: () => _showActivityDetailModal(context, activeRec),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_filled,
                          size: 18,
                          color: Color(0xFF5B61D6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mulai Latihan Sekarang',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5B61D6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showActivityDetailModal(
      BuildContext context, Map<String, dynamic> activity) {
    final title = activity['title']?.toString() ?? 'Latihan Relaksasi';
    final category = activity['category']?.toString() ?? 'Self-Care';
    final duration = activity['duration']?.toString() ?? '5 menit';
    final difficulty = activity['difficulty']?.toString() ?? 'Pemula';
    final description = activity['description']?.toString() ?? '';
    final rationale = activity['rationale']?.toString() ?? '';
    final rawInstructions = activity['instructions'];
    final List<String> instructions = rawInstructions is List
        ? List<String>.from(rawInstructions.map((e) => e.toString()))
        : <String>[];
    final id = activity['id']?.toString() ?? '';

    final displayRationale =
        rationale.isNotEmpty ? rationale : _conditionReason;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentDone = (_todayActivity != null &&
                    _todayActivity!['id'] == id)
                ? (_todayActivity!['isCompleted'] == true)
                : _localProgress.isActivityCompleted(id);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Tags
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '⏱️ $duration',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• $difficulty',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Clinical Rationale Box (if present)
                  if (displayRationale.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFDDD6FE),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayRationale,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                height: 1.4,
                                color: const Color(0xFF5B21B6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Step-by-step instructions
                  if (instructions.isNotEmpty) ...[
                    Text(
                      'Langkah-Langkah Latihan:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: instructions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  instructions[i],
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _toggleRecommendationComplete(id);
                            setModalState(() {});
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentDone
                                ? const Color(0xFF10B981)
                                : AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                currentDone
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentDone
                                    ? 'Selesai Dilakukan'
                                    : 'Tandai Selesai',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
