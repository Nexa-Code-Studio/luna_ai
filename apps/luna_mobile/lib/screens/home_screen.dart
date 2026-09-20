import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/daily_progress_local_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/staggered_entrance.dart';

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
  bool _hasTodayDass = false;
  bool _dassVerifiedByUser = false;
  String _dassStatus = '';
  int _dassStressScore = 0;
  int _dassAnxietyScore = 0;
  int _dassDepressionScore = 0;
  String _targetCondition = 'general';
  String _conditionLabel = 'Fokus: Relaksasi & Perawatan Diri';
  String _conditionReason = 'Menjaga ritme emosi dan ketenangan pikiran harian';
  String _severityLevel = 'Normal';
  bool _isCrisis = false;
  String _crisisHotline = 'Kemenkes 119 ext 8 / LISA 0811-3855-472';
  String _crisisGuidance =
      'Keselamatan dan ketenanganmu adalah prioritas paling berharga. Silakan hubungi bantuan darurat bila beban terasa terlalu berat.';
  Map<String, dynamic>? _todayActivity;

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'berat':
      case 'sangat berat':
      case 'krisis / darurat':
        return const Color(0xFFEF4444);
      case 'sedang':
        return const Color(0xFFF59E0B);
      case 'ringan':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _normalizeCategory(String? raw) {
    final cat = (raw ?? '').toLowerCase();
    if (cat.contains('mindful') || cat.contains('napas') || cat.contains('breath')) return 'Mindfulness';
    if (cat.contains('cbt') || cat.contains('kognitif') || cat.contains('problem')) return 'CBT';
    if (cat.contains('refleksi') || cat.contains('syukur') || cat.contains('self-care')) return 'Refleksi';
    if (cat.contains('fisik') || cat.contains('gerak') || cat.contains('somatis') || cat.contains('aktivasi') || cat.contains('jalan')) return 'Fisik & Gerak';
    return raw?.isNotEmpty == true ? raw! : 'Self-Care';
  }

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
        // 4: Today DASS-21 assessment
        http
            .get(
              Uri.parse('${AppConfig.baseUrl}/dass/today'),
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
          _severityLevel = data['severityLevel']?.toString() ?? 'Normal';
          _isCrisis = data['isCrisis'] == true;
          if (data['crisisHotline'] != null) {
            _crisisHotline = data['crisisHotline'].toString();
          }
          if (data['crisisGuidance'] != null) {
            _crisisGuidance = data['crisisGuidance'].toString();
          }

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

      // Handle Today DASS-21 Assessment
      if (results.length > 4) {
        final resDass = results[4];
        if (resDass.statusCode == 200) {
          final dynamic data = jsonDecode(resDass.body);
          if (data is Map<String, dynamic>) {
            _hasTodayDass = data['id'] != null;
            _dassVerifiedByUser =
                data['verifiedByUser'] == true || data['verified_by_user'] == true;
            _dassStatus = data['status']?.toString() ?? '';
            _dassStressScore =
                (data['stressScore'] ?? data['stress_score'] ?? 0) as int;
            _dassAnxietyScore =
                (data['anxietyScore'] ?? data['anxiety_score'] ?? 0) as int;
            _dassDepressionScore =
                (data['depressionScore'] ?? data['depression_score'] ?? 0) as int;
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
              StaggeredEntrance(
                index: 0,
                child: Padding(
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
                    ],
                  ),
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
                        StaggeredEntrance(
                          index: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Empathetic AI Psychologist Insight Card
                        StaggeredEntrance(
                          index: 2,
                          child: _buildLunaInsightCard(),
                        ),
                        const SizedBox(height: 20),

                        // Quick Navigation Shortcuts
                        StaggeredEntrance(
                          index: 3,
                          child: _buildQuickActionShortcuts(),
                        ),
                        const SizedBox(height: 24),

                        // Evidence-Based Daily Progress Section (3 Pillars)
                        StaggeredEntrance(
                          index: 4,
                          child: _buildDailyProgressSection(),
                        ),
                        const SizedBox(height: 24),

                        // Latest Clinically-Informed Recommendation
                        StaggeredEntrance(
                          index: 5,
                          child: _buildLatestRecommendationSection(),
                        ),
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
          title: 'Asesmen DASS-21',
          subtitle: _dassVerifiedByUser
              ? 'Stres: $_dassStressScore • Cemas: $_dassAnxietyScore • Depresi: $_dassDepressionScore'
              : (_hasTodayDass && _dassStatus == 'auto_extracted'
                  ? 'Tersintesis AI • Ketuk untuk meninjau'
                  : 'Evaluasi & koreksi 21 butir emosi'),
          badgeText: _dassVerifiedByUser
              ? 'Terverifikasi ✓'
              : (_hasTodayDass && _dassStatus == 'auto_extracted'
                  ? 'Perlu Ditinjau ⚡'
                  : 'Belum Diisi'),
          badgeColor: _dassVerifiedByUser
              ? const Color(0xFF059669)
              : (_hasTodayDass && _dassStatus == 'auto_extracted'
                  ? const Color(0xFFD97706)
                  : AppColors.primary),
          badgeBg: _dassVerifiedByUser
              ? const Color(0xFFECFDF5)
              : (_hasTodayDass && _dassStatus == 'auto_extracted'
                  ? const Color(0xFFFEF3C7)
                  : AppColors.primaryContainer.withValues(alpha: 0.6)),
          onTap: () async {
            await Navigator.pushNamed(context, '/dass_assessment');
            _loadHomeScreenData();
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
    Color? badgeColor,
    Color? badgeBg,
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
              color: badgeBg ?? AppColors.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: badgeColor ?? AppColors.primary,
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
          'Luar biasa! Semua target perawatan dirimu tercapai hari ini 🌟';
    } else if (completed == 2) {
      progressMotivation =
          'Tinggal 1 langkah lagi untuk melengkapi rutinitas terapeutikmu.';
    } else if (completed == 1) {
      progressMotivation =
          'Kemajuan yang sangat baik! Terus jaga ritme emosionalmu.';
    } else {
      progressMotivation =
          'Mulai harimu dengan satu langkah kecil penuh perhatian bersama LUNA.';
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
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: completed == 3
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    completed == 3 ? Icons.stars_rounded : Icons.spa_rounded,
                    size: 16,
                    color: completed == 3
                        ? const Color(0xFF10B981)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Progres Perawatan Diri',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: completed == 3
                    ? const Color(0xFFD1FAE5)
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: completed == 3
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (completed == 3) ...[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: Color(0xFF047857),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '$completed / 3 Selesai',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: completed == 3
                          ? const Color(0xFF047857)
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Premium Progress Container
        GlassCard(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented 3-Step Progress Bars
              Row(
                children: [
                  Expanded(
                    child: _buildSegmentBar(isActive: isConversationDone),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildSegmentBar(isActive: isDiaryDone),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildSegmentBar(isActive: isExerciseDone),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Motivation & Percentage Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: completed == 3
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: completed == 3
                        ? const Color(0xFF86EFAC).withValues(alpha: 0.5)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      completed == 3
                          ? Icons.emoji_events_rounded
                          : Icons.auto_awesome,
                      size: 16,
                      color: completed == 3
                          ? const Color(0xFF10B981)
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        progressMotivation,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: completed == 3
                              ? const Color(0xFF065F46)
                              : AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: completed == 3
                            ? const Color(0xFF10B981)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${(progressFraction * 100).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Routine 1: Sesi Curhat / Dialog Emosi
              _buildProgressCheckItem(
                title: 'Sesi Curhat Bersama Luna',
                subtitle: isConversationDone
                    ? '$_todayConversationsCount sesi dialog telah tercatat hari ini'
                    : 'Ekspresikan perasaanmu lewat suara atau teks',
                icon: Icons.chat_bubble_outline_rounded,
                isCompleted: isConversationDone,
                onTap: () => Navigator.pushNamed(context, '/chat'),
              ),
              const SizedBox(height: 8),

              // Routine 2: Refleksi Jurnal AI
              _buildProgressCheckItem(
                title: 'Refleksi Jurnal Harian',
                subtitle: isDiaryDone
                    ? 'Jurnal & analisis emosi telah disintesis'
                    : 'Baca rangkuman & pola emosimu hari ini',
                icon: Icons.menu_book_rounded,
                isCompleted: isDiaryDone,
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1);
                  } else {
                    Navigator.pushNamed(context, '/diary');
                  }
                },
              ),
              const SizedBox(height: 8),

              // Routine 3: Latihan Koping Terpandu
              _buildProgressCheckItem(
                title: 'Latihan Relaksasi & Koping',
                subtitle: isExerciseDone
                    ? '1 latihan koping mandiri telah diselesaikan'
                    : 'Coba 1 teknik pernapasan atau mindfulness',
                icon: Icons.spa_rounded,
                isCompleted: isExerciseDone,
                onTap: () => Navigator.pushNamed(context, '/recommendation'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentBar({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildProgressCheckItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFFF0FDF4)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF86EFAC).withValues(alpha: 0.6)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : AppColors.primaryContainer,
                  boxShadow: isCompleted
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : icon,
                  size: isCompleted ? 18 : 17,
                  color: isCompleted ? Colors.white : AppColors.primary,
                ),
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Action Pill / Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFD1FAE5)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCompleted ? 'Selesai' : 'Mulai',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? const Color(0xFF047857)
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      isCompleted
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 12,
                      color: isCompleted
                          ? const Color(0xFF047857)
                          : AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4. Tailored Daily Recommendation Container
  // --------------------------------------------------------------------------
  Widget _buildCrisisBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFDC2626),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kamu Berharga & Tidak Sendirian',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                    Text(
                      'Prioritas Utama: Keselamatan & Bantuan Nyata',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFB91C1C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _crisisGuidance,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              height: 1.4,
              color: const Color(0xFF7F1D1D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hotline: $_crisisHotline',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/support');
              },
              icon: const Icon(Icons.support_agent, size: 16, color: Colors.white),
              label: Text(
                'Pusat Bantuan & Hotline Darurat',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    final rawCategory = activeRec['category']?.toString() ?? 'Self-Care';
    final category = _normalizeCategory(rawCategory);
    final duration = activeRec['duration']?.toString() ?? '5 menit';
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
          _conditionLabel.isNotEmpty
              ? _conditionLabel
              : 'Disesuaikan dengan kondisi emosionalmu hari ini',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Crisis Alert Banner (if applicable)
        if (_isCrisis) _buildCrisisBanner(),

        // Clean, Sleek Recommendation Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4F46E5),
                Color(0xFF6366F1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row: Category • Duration + Severity Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$category  •  $duration'.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (_severityLevel != 'Normal')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(_severityLevel)
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getSeverityColor(_severityLevel)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'Level: $_severityLevel',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),

                // Description (clean, concise)
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 16),

                // Bottom Action Buttons: Mulai Latihan (CTA) + Tandai Selesai
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            _showActivityDetailModal(context, activeRec),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.play_circle_filled,
                                size: 18,
                                color: Color(0xFF4F46E5),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isDone ? 'Buka Panduan' : 'Mulai Latihan',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        if (isDone) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Kamu sudah menyelesaikan latihan ini hari ini! Kerja bagus, istirahatlah sejenak dan lanjutkan kembali besok 🌿',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF6366F1),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        _toggleRecommendationComplete(id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF10B981)
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDone
                                ? const Color(0xFF10B981)
                                : Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDone
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isDone ? 'Selesai' : 'Tandai',
                              style: GoogleFonts.inter(
                                fontSize: 12,
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showActivityDetailModal(
      BuildContext context, Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final id = activity['id']?.toString() ?? '';
        final isDone = (_todayActivity != null && _todayActivity!['id'] == id)
            ? (_todayActivity!['isCompleted'] == true)
            : _localProgress.isActivityCompleted(id);

        return _HomeActivityModalContent(
          activity: activity,
          conditionReason: _conditionReason,
          isCompleted: isDone,
          onComplete: () async {
            if (isDone) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kamu sudah menyelesaikan latihan ini hari ini! Kerja bagus, istirahatlah sejenak dan lanjutkan kembali besok 🌿',
                          style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF6366F1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 3),
                ),
              );
              Navigator.pop(ctx);
              return;
            }
            await _toggleRecommendationComplete(id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bagus sekali! Satu langkah kecil untuk ketenanganmu telah selesai.',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 3),
                ),
              );
              Navigator.pop(ctx);
            }
          },
        );
      },
    );
  }
}

/// Modal bottom sheet content for home screen with rationale, steps, and breath pacer
class _HomeActivityModalContent extends StatefulWidget {
  final Map<String, dynamic> activity;
  final String conditionReason;
  final bool isCompleted;
  final VoidCallback onComplete;

  const _HomeActivityModalContent({
    required this.activity,
    required this.conditionReason,
    required this.isCompleted,
    required this.onComplete,
  });

  @override
  State<_HomeActivityModalContent> createState() =>
      _HomeActivityModalContentState();
}

class _HomeActivityModalContentState extends State<_HomeActivityModalContent> {
  bool _isBreathPacerActive = false;
  int _breathTimerSec = 0;
  String _breathPhase = 'Tarik Napas';
  Timer? _breathTimer;

  @override
  void dispose() {
    _breathTimer?.cancel();
    super.dispose();
  }

  void _toggleBreathPacer() {
    if (_isBreathPacerActive) {
      _breathTimer?.cancel();
      setState(() {
        _isBreathPacerActive = false;
        _breathTimerSec = 0;
        _breathPhase = 'Selesai';
      });
    } else {
      setState(() {
        _isBreathPacerActive = true;
        _breathTimerSec = 0;
        _breathPhase = 'Tarik Napas (4 dtk)';
      });

      _breathTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _breathTimerSec++;
          final cycle = _breathTimerSec % 19;
          if (cycle < 4) {
            _breathPhase = 'Tarik Napas Perlahan (4s)';
          } else if (cycle < 11) {
            _breathPhase = 'Tahan Napas di Dada (7s)';
          } else {
            _breathPhase = 'Hembuskan Napas Rileks (8s)';
          }
        });
      });
    }
  }

  String _normalizeCategory(String? raw) {
    final cat = (raw ?? '').toLowerCase();
    if (cat.contains('mindful') || cat.contains('napas') || cat.contains('breath')) return 'Mindfulness';
    if (cat.contains('cbt') || cat.contains('kognitif') || cat.contains('problem')) return 'CBT';
    if (cat.contains('refleksi') || cat.contains('syukur') || cat.contains('self-care')) return 'Refleksi';
    if (cat.contains('fisik') || cat.contains('gerak') || cat.contains('somatis') || cat.contains('aktivasi') || cat.contains('jalan')) return 'Fisik & Gerak';
    return raw?.isNotEmpty == true ? raw! : 'Self-Care';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.activity['title']?.toString() ?? 'Latihan Relaksasi';
    final rawCat = widget.activity['category']?.toString() ?? 'Self-Care';
    final category = _normalizeCategory(rawCat);
    final duration = widget.activity['duration']?.toString() ?? '5 menit';
    final difficulty = widget.activity['difficulty']?.toString() ?? 'Pemula';
    final description = widget.activity['description']?.toString() ?? '';
    final rationale = widget.activity['rationale']?.toString() ?? '';
    final rawInstructions = widget.activity['instructions'];
    List<String> instructions = rawInstructions is List
        ? List<String>.from(rawInstructions.map((e) => e.toString()))
        : <String>[];

    if (instructions.isEmpty) {
      instructions = [
        'Cari posisi duduk yang santai dan nyaman.',
        'Tarik napas dalam perlahan dan hembuskan perlahan.',
        'Lakukan langkah latihan ini secara tenang selama $duration.',
        'Rasakan perubahan sensasi rileks di tubuhmu setelah selesai.'
      ];
    }

    final displayRationale =
        rationale.isNotEmpty ? rationale : widget.conditionReason;

    final isBreathingActivity = title.toLowerCase().contains('napas') ||
        title.toLowerCase().contains('breath') ||
        category.toLowerCase() == 'mindfulness';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header tags & close button (X)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•  $duration  •  $difficulty',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Rationale Card
                  if (displayRationale.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kenapa Latihan Ini Membantu?',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF5B21B6),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  displayRationale,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: const Color(0xFF6D28D9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 2. Interactive Breath Pacer (if relevant)
                  if (isBreathingActivity) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFEEF2FF),
                            Color(0xFFE0E7FF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.air,
                                      size: 16, color: Color(0xFF4F46E5)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pemandu Irama Napas',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF3730A3),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _toggleBreathPacer,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isBreathPacerActive
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF4F46E5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _isBreathPacerActive
                                        ? 'Hentikan'
                                        : 'Mulai Pemandu',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isBreathPacerActive) ...[
                            const SizedBox(height: 14),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 700),
                              width: _breathPhase.contains('Tarik') ? 80 : 65,
                              height: _breathPhase.contains('Tarik') ? 80 : 65,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.2),
                                border: Border.all(
                                    color: const Color(0xFF4F46E5), width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${_breathTimerSec}s',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF3730A3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _breathPhase,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF4338CA),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. Step-by-step instructions
                  Text(
                    'Langkah-Langkah yang Perlu Dilakukan:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: instructions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              instructions[idx],
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Completion Button CTA
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onComplete,
              icon: Icon(
                widget.isCompleted ? Icons.check_circle : Icons.check,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                widget.isCompleted
                    ? 'Sudah Diselesaikan Hari Ini'
                    : 'Saya Sudah Melakukan Latihan Ini',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isCompleted
                    ? const Color(0xFF10B981)
                    : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
