import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/daily_progress_local_service.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  static final List<Map<String, dynamic>> _defaultRecommendations = [
    {
      'id': 'c1',
      'title': 'Latihan Pernapasan 4-7-8',
      'category': 'Mindfulness',
      'targetCondition': 'stress',
      'duration': '3-5 Menit',
      'difficulty': 'Pemula',
      'description':
          'Tarik napas dalam 4 detik, tahan 7 detik, lalu hembuskan perlahan 8 detik untuk meredakan ketegangan sistem saraf.',
      'instructions': [
        'Duduk dengan posisi santai dan tegakkan punggung.',
        'Tarik napas perlahan lewat hidung selama 4 detik.',
        'Tahan napas di rongga dada selama 7 detik.',
        'Hembuskan napas perlahan lewat mulut selama 8 detik hingga dada terasa rileks.',
        'Ulangi siklus ini sebanyak 4 hingga 5 kali.'
      ],
      'rationale':
          'Mengaktifkan saraf parasimpatik (vagus nerve) untuk menurunkan denyut jantung dan meredakan ketegangan fisiologis.',
      'iconName': 'air',
      'isCompleted': false,
    },
    {
      'id': 'c2',
      'title': 'Teknik Grounding 5-4-3-2-1',
      'category': 'CBT',
      'targetCondition': 'anxiety',
      'duration': '5 Menit',
      'difficulty': 'Pemula',
      'description':
          'Sadarilah 5 hal yang dilihat, 4 yang disentuh, 3 suara, 2 aroma, dan 1 rasa untuk meredakan overthinking.',
      'instructions': [
        'Lihat ke sekitarmu: Sebutkan 5 benda yang dapat kamu lihat saat ini.',
        'Sentuh benda di dekatmu: Rasakan 4 tekstur berbeda (pakaian, meja, jari tangan).',
        'Dengarkan secara saksama: Sadari 3 suara di sekitarmu (kipas, kendaraan, napas).',
        'Hirup udara: Sadari 2 aroma di sekitarmu.',
        'Rasakan mulutmu: Sadari 1 rasa di lidahmu saat ini.'
      ],
      'rationale':
          'Mengalihkan fokus otak dari overthinking dan badai cemas kembali ke realitas fisik saat ini.',
      'iconName': 'psychology',
      'isCompleted': false,
    },
    {
      'id': 'c3',
      'title': 'Catatan Syukur Harian',
      'category': 'Refleksi',
      'targetCondition': 'depression',
      'duration': '3 Menit',
      'difficulty': 'Pemula',
      'description':
          'Tuliskan hal-hal sederhana yang memberi kehangatan atau rasa nyaman hari ini.',
      'instructions': [
        'Ambil buku catatan kecil atau gunakan catatan di ponselmu.',
        'Pikirkan 1 hingga 3 hal kecil yang terjadi hari ini (misal: secangkir teh hangat, udara sejuk).',
        'Tuliskan secara singkat mengapa hal itu terasa bermakna bagimu.',
        'Rasakan sensasi lega dan hangat di dalam hatimu sejenak.'
      ],
      'rationale':
          'Mengimbangi bias negatif kognitif pada suasana hati murung dengan melatih fokus pada hal positif.',
      'iconName': 'edit_note',
      'isCompleted': false,
    },
    {
      'id': 'c9',
      'title': 'Metode Notice and Name',
      'category': 'CBT',
      'targetCondition': 'anxiety',
      'duration': '4 Menit',
      'difficulty': 'Menengah',
      'description':
          'Lepaskan diri dari pikiran cemas yang menjebak dengan mengenali dan menamainya.',
      'instructions': [
        'Ketika pikiran cemas muncul, berhenti sejenak tanpa menghakiminya.',
        'Katakan pada diri sendiri: "Aku sedang menyadari pikiran bahwa..."',
        'Ingat bahwa pikiran hanyalah kata-kata atau gambaran mental, bukan fakta pasti.',
        'Bernapas perlahan dan biarkan pikiran tersebut berlalu seperti awan di langit.'
      ],
      'rationale':
          'Membantu defusi kognitif agar kamu tidak larut dan terseret oleh lingkaran pikiran cemas.',
      'iconName': 'psychology',
      'isCompleted': false,
    },
    {
      'id': 'c10',
      'title': 'Metode Stop-Think-Go',
      'category': 'CBT',
      'targetCondition': 'stress',
      'duration': '5 Menit',
      'difficulty': 'Menengah',
      'description':
          'Teknik pemecahan masalah bertahap saat pikiran terasa menumpuk dan membebani.',
      'instructions': [
        'STOP: Berhenti sejenak dari aktivitasmu, letakkan ponsel, dan ambil satu napas panjang.',
        'THINK: Uraikan apa yang sebenarnya sedang terjadi dan apa yang bisa kamu kendalikan saat ini.',
        'GO: Pilih 1 tindakan terkecil yang bisa kamu lakukan sekarang tanpa perlu menyelesaikan semuanya sekaligus.'
      ],
      'rationale':
          'Mencegah respon panik atau impulsif ketika merasa kewalahan dengan memecah masalah menjadi langkah mikro.',
      'iconName': 'psychology',
      'isCompleted': false,
    },
    {
      'id': 'c4',
      'title': 'Jalan Santai Mindful',
      'category': 'Aktivitas Fisik',
      'targetCondition': 'general',
      'duration': '10 Menit',
      'difficulty': 'Pemula',
      'description':
          'Berjalan santai di ruangan atau luar ruangan sambil memperhatikan sensasi langkah kaki.',
      'instructions': [
        'Berdiri tegak, rilekskan bahu dan rahangmu.',
        'Mulai melangkah dengan ritme santai dan perlahan.',
        'Fokuskan perhatian pada telapak kakimu yang menyentuh tanah pada setiap langkah.',
        'Jika pikiranmu melayang, dengan lembut bawa kembali perhatianmu pada langkah kaki.'
      ],
      'rationale':
          'Menggabungkan gerakan fisik ringan dengan perhatian sadar untuk memulihkan energi dan kejernihan pikiran.',
      'iconName': 'directions_walk',
      'isCompleted': false,
    },
  ];

  String _conditionLabel = 'Fokus: Relaksasi & Perawatan Diri';
  String _conditionReason =
      'Berikut beberapa panduan terstruktur untuk membantumu meredakan ketegangan dan menjaga ketenangan hari ini.';
  String _severityLevel = 'Normal';
  bool _isCrisis = false;
  String _crisisHotline = 'Kemenkes 119 ext 8 / LISA 0811-3855-472';
  String _crisisGuidance =
      'Keselamatan dan ketenanganmu adalah prioritas paling berharga. Silakan hubungi bantuan darurat bila beban terasa terlalu berat.';

  Map<String, dynamic>? _todayActivity;
  List<Map<String, dynamic>> _recommendations = [];
  String _selectedCategory = 'Semua';
  bool _isLoading = false;

  final List<String> _categories = [
    'Semua',
    'Mindfulness',
    'CBT',
    'Refleksi',
    'Fisik & Gerak',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    final localProgress = await DailyProgressLocalService.loadTodayProgress();

    if (AppConfig.useMockData) {
      setState(() {
        _recommendations = _defaultRecommendations.map((r) {
          final copy = Map<String, dynamic>.from(r);
          final rId = copy['id']?.toString() ?? '';
          copy['isCompleted'] = localProgress.isActivityCompleted(rId);
          return copy;
        }).toList();
        _todayActivity = _recommendations.firstWhere(
          (r) => r['isCompleted'] != true,
          orElse: () => _recommendations.first,
        );
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final headers = await AppConfig.getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/recommendations/today'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (mounted) {
          final rawToday = data['todayActivity'] as Map<String, dynamic>?;
          final rawAll = (data['allRecommendations'] as List<dynamic>?) ??
              (data['alternatives'] as List<dynamic>?) ??
              [];

          Map<String, dynamic>? mappedToday;
          if (rawToday != null) {
            final tId = rawToday['id']?.toString() ?? '';
            mappedToday = _normalizeActivity(rawToday, localProgress.isActivityCompleted(tId));
          }

          final List<Map<String, dynamic>> mappedList = [];
          if (mappedToday != null) {
            mappedList.add(mappedToday);
          }

          for (var item in rawAll) {
            if (item is Map<String, dynamic>) {
              final aId = item['id']?.toString() ?? '';
              if (mappedToday != null && aId == mappedToday['id']) continue;
              mappedList.add(_normalizeActivity(item, localProgress.isActivityCompleted(aId)));
            }
          }

          setState(() {
            _conditionLabel = data['conditionLabel']?.toString() ?? 'Fokus: Perawatan Diri';
            _conditionReason = data['conditionReason']?.toString() ?? '';
            _severityLevel = data['severityLevel']?.toString() ?? 'Normal';
            _isCrisis = data['isCrisis'] == true;
            _crisisHotline = data['crisisHotline']?.toString() ?? _crisisHotline;
            _crisisGuidance = data['crisisGuidance']?.toString() ?? _crisisGuidance;
            _todayActivity = mappedToday ?? (mappedList.isNotEmpty ? mappedList.first : null);
            _recommendations = mappedList.isNotEmpty ? mappedList : _defaultRecommendations;
          });
        }
      } else {
        _useFallbackData(localProgress);
      }
    } catch (_) {
      _useFallbackData(localProgress);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _useFallbackData(DailyProgressData localProgress) {
    if (!mounted) return;
    setState(() {
      _recommendations = _defaultRecommendations.map((r) {
        final copy = Map<String, dynamic>.from(r);
        final rId = copy['id']?.toString() ?? '';
        copy['isCompleted'] = localProgress.isActivityCompleted(rId);
        return copy;
      }).toList();
      _todayActivity = _recommendations.firstWhere(
        (r) => r['isCompleted'] != true,
        orElse: () => _recommendations.first,
      );
    });
  }

  Map<String, dynamic> _normalizeActivity(Map<String, dynamic> raw, bool isDone) {
    final actId = raw['id']?.toString() ?? '';
    final instructionsRaw = raw['instructions'];
    List<String> instructions = [];
    if (instructionsRaw is List) {
      instructions = instructionsRaw.map((e) => e.toString()).toList();
    }

    return {
      'id': actId,
      'title': raw['title']?.toString() ?? 'Latihan Relaksasi',
      'category': raw['category']?.toString() ?? 'Mindfulness',
      'targetCondition': raw['targetCondition']?.toString() ?? 'general',
      'duration': raw['duration']?.toString() ?? '5 Menit',
      'difficulty': raw['difficulty']?.toString() ?? raw['level']?.toString() ?? 'Pemula',
      'description': raw['description']?.toString() ?? '',
      'instructions': instructions,
      'rationale': raw['rationale']?.toString() ?? '',
      'iconName': raw['iconName']?.toString() ?? 'spa',
      'isCompleted': raw['isCompleted'] == true || isDone,
    };
  }

  Future<void> _completeRecommendation(String id) async {
    final idx = _recommendations.indexWhere((r) => r['id'] == id);
    final bool alreadyDone = (idx != -1 && _recommendations[idx]['isCompleted'] == true) ||
        (_todayActivity != null && _todayActivity!['id'] == id && _todayActivity!['isCompleted'] == true);

    if (alreadyDone) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kamu sudah menyelesaikan latihan ini hari ini! Kerja bagus, istirahatlah sejenak dan lanjutkan kembali besok 🌿',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF6366F1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      if (idx != -1) {
        _recommendations[idx]['isCompleted'] = true;
      }
      if (_todayActivity != null && _todayActivity!['id'] == id) {
        _todayActivity!['isCompleted'] = true;
      }
    });

    await DailyProgressLocalService.recordActivityCompletion(id, true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bagus sekali! Satu langkah kecil untuk ketenanganmu telah selesai.',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (AppConfig.useMockData) return;
    try {
      final headers = await AppConfig.getAuthHeaders();
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/recommendations/$id/complete'),
        headers: headers,
      );
    } catch (_) {}
  }

  IconData _getIconForActivity(String? iconName, String? category) {
    if (iconName != null) {
      switch (iconName.toLowerCase()) {
        case 'air':
          return Icons.air;
        case 'spa':
          return Icons.spa;
        case 'psychology':
          return Icons.psychology;
        case 'edit_note':
          return Icons.edit_note;
        case 'directions_walk':
          return Icons.directions_walk;
        case 'emergency':
          return Icons.emergency;
        case 'task_alt':
          return Icons.task_alt;
        case 'phonelink_off':
          return Icons.phonelink_off;
        case 'self_improvement':
          return Icons.self_improvement;
      }
    }
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('mindful') || cat.contains('napas')) return Icons.air;
    if (cat.contains('refleksi') || cat.contains('self-care') || cat.contains('syukur')) return Icons.edit_note;
    if (cat.contains('cbt') || cat.contains('problem') || cat.contains('kognitif')) return Icons.psychology;
    if (cat.contains('somatis') || cat.contains('fisik') || cat.contains('aktivasi') || cat.contains('jalan')) return Icons.directions_walk;
    if (cat.contains('krisis') || cat.contains('darurat')) return Icons.emergency;
    return Icons.self_improvement;
  }

  Color _getCategoryColor(String? category) {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('mindful') || cat.contains('napas')) return const Color(0xFF6366F1);
    if (cat.contains('refleksi') || cat.contains('self-care') || cat.contains('syukur')) return const Color(0xFF8B5CF6);
    if (cat.contains('cbt') || cat.contains('problem') || cat.contains('kognitif')) return const Color(0xFF0EA5E9);
    if (cat.contains('somatis') || cat.contains('fisik') || cat.contains('aktivasi') || cat.contains('jalan')) return const Color(0xFF10B981);
    if (cat.contains('krisis') || cat.contains('darurat')) return const Color(0xFFEF4444);
    return AppColors.primary;
  }

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

  bool _matchesCategory(String? category, String selected) {
    if (selected == 'Semua') return true;
    final cat = (category ?? '').toLowerCase();
    switch (selected) {
      case 'Mindfulness':
        return cat.contains('mindful') || cat.contains('napas') || cat.contains('breath');
      case 'CBT':
        return cat.contains('cbt') || cat.contains('kognitif') || cat.contains('problem') || cat.contains('unhooking');
      case 'Refleksi':
        return cat.contains('refleksi') || cat.contains('syukur') || cat.contains('self-care') || cat.contains('catatan');
      case 'Fisik & Gerak':
        return cat.contains('fisik') || cat.contains('gerak') || cat.contains('somatis') || cat.contains('aktivasi') || cat.contains('jalan');
      default:
        return cat.contains(selected.toLowerCase());
    }
  }

  int _getCategoryCount(String category) {
    if (category == 'Semua') return _recommendations.length;
    return _recommendations.where((r) => _matchesCategory(r['category']?.toString(), category)).length;
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecommendations = _selectedCategory == 'Semua'
        ? _recommendations
        : _recommendations
            .where((r) => _matchesCategory(r['category']?.toString(), _selectedCategory))
            .toList();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF7F9FD),
              Color(0xFFEFF3FD),
              Color(0xFFF7F8FE),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchRecommendations,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 80.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Crisis Emergency Banner (if applicable)
                              if (_isCrisis) ...[
                                _buildCrisisBanner(),
                                const SizedBox(height: 18),
                              ],

                              // 2. Clinically Tailored Condition Header Card
                              _buildConditionContextCard(),
                              const SizedBox(height: 20),

                              // 3. Featured Activity of the Day
                              if (_todayActivity != null) ...[
                                Text(
                                  'Aktivitas Utama Hari Ini',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Langkah kecil paling relevan untuk menenangkan pikiranmu saat ini.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildFeaturedTodayCard(_todayActivity!),
                                const SizedBox(height: 24),
                              ],

                              // 4. Category Filter Chips
                              Text(
                                'Pilihan Latihan Ketenangan',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pilih teknik yang paling nyaman dan sesuai kebutuhanmu.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildCategorySelector(),
                              const SizedBox(height: 14),

                              // 5. List of Recommended Activities
                              if (filteredRecommendations.isEmpty)
                                _buildEmptyState()
                              else
                                ...filteredRecommendations.map((rec) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: _buildActivityCard(rec),
                                  );
                                }),
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

  Widget _buildTopBar() {
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.pop(context),
            )
          else
            Image.asset(
              'assets/images/luna_logo.png',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.nightlight_round,
                size: 26,
                color: AppColors.primary,
              ),
            ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Panduan Ketenangan',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Latihan & Pemulihan Mandiri',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Perbarui Panduan',
            icon: const Icon(Icons.refresh, size: 22),
            color: AppColors.primary,
            onPressed: _fetchRecommendations,
          ),
        ],
      ),
    );
  }

  Widget _buildCrisisBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFDC2626),
                  size: 20,
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
                        fontSize: 14,
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
          const SizedBox(height: 10),
          Text(
            _crisisGuidance,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: const Color(0xFF7F1D1D),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/support');
                  },
                  icon: const Icon(Icons.support_agent, size: 18, color: Colors.white),
                  label: Text(
                    'Pusat Bantuan & Hotline',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionContextCard() {
    final sevColor = _getSeverityColor(_severityLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5358CB).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _conditionLabel.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: sevColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Level: $_severityLevel',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: sevColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _conditionReason.isNotEmpty
                ? _conditionReason
                : 'Panduan ini dipilih agar kamu tahu apa yang harus dilakukan tanpa bingung, langkah demi langkah.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTodayCard(Map<String, dynamic> act) {
    final isDone = act['isCompleted'] == true;
    final title = act['title']?.toString() ?? 'Latihan Relaksasi';
    final desc = act['description']?.toString() ?? '';
    final duration = act['duration']?.toString() ?? '5 Menit';
    final category = act['category']?.toString() ?? 'Mindfulness';
    final difficulty = act['difficulty']?.toString() ?? 'Pemula';
    final rationale = act['rationale']?.toString() ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF6366F1),
            Color(0xFF818CF8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '$duration • $difficulty',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            if (rationale.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, size: 13, color: Colors.amberAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        rationale,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showGuidanceModal(context, act),
                    icon: const Icon(Icons.play_circle_fill, size: 18, color: Color(0xFF4F46E5)),
                    label: Text(
                      'Buka Panduan Langkah',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _completeRecommendation(act['id'].toString()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF10B981)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDone
                            ? const Color(0xFF10B981)
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDone ? Icons.check_circle : Icons.check_circle_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDone ? 'Selesai' : 'Tandai',
                          style: GoogleFonts.inter(
                            fontSize: 11,
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
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          final count = _getCategoryCount(cat);
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cat,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> act) {
    final isDone = act['isCompleted'] == true;
    final title = act['title']?.toString() ?? '';
    final subtitle = act['description']?.toString() ?? '';
    final category = act['category']?.toString() ?? 'Mindfulness';
    final duration = act['duration']?.toString() ?? '5 Menit';
    final catColor = _getCategoryColor(category);
    final icon = _getIconForActivity(act['iconName']?.toString(), category);

    return GlassCard(
      width: double.infinity,
      onTap: () => _showGuidanceModal(context, act),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDone ? Colors.grey.shade400 : catColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              color: isDone ? Colors.white : catColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: catColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  $duration',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isDone ? Icons.check_circle : Icons.chevron_right,
              color: isDone ? const Color(0xFF10B981) : AppColors.textLight,
              size: 22,
            ),
            onPressed: () => _showGuidanceModal(context, act),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            const Icon(Icons.self_improvement, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'Belum ada panduan di kategori ini',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Silakan pilih kategori "Semua" untuk melihat latihan lainnya.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  /// Interactive step-by-step guidance bottom sheet
  void _showGuidanceModal(BuildContext context, Map<String, dynamic> act) {
    final actId = act['id']?.toString() ?? '';
    final title = act['title']?.toString() ?? 'Latihan Relaksasi';
    final category = act['category']?.toString() ?? 'Mindfulness';
    final duration = act['duration']?.toString() ?? '5 Menit';
    final difficulty = act['difficulty']?.toString() ?? 'Pemula';
    final description = act['description']?.toString() ?? '';
    final rationale = act['rationale']?.toString() ?? '';

    List<String> instructions = [];
    if (act['instructions'] is List) {
      instructions = (act['instructions'] as List).map((e) => e.toString()).toList();
    }
    if (instructions.isEmpty) {
      // Fallback instructions if missing
      instructions = [
        'Cari posisi duduk yang santai dan nyaman.',
        'Tarik napas dalam perlahan dan hembuskan perlahan.',
        'Lakukan langkah latihan ini secara tenang selama $duration.',
        'Rasakan perubahan sensasi rileks di tubuhmu setelah selesai.'
      ];
    }

    final isBreathingActivity = title.toLowerCase().contains('napas') ||
        title.toLowerCase().contains('breathing') ||
        category.toLowerCase() == 'mindfulness';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _GuidanceModalContent(
          actId: actId,
          title: title,
          category: category,
          duration: duration,
          difficulty: difficulty,
          description: description,
          rationale: rationale,
          instructions: instructions,
          isBreathingActivity: isBreathingActivity,
          isCompleted: act['isCompleted'] == true,
          onComplete: () {
            _completeRecommendation(actId);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }
}

/// Dedicated stateful widget for modal with optional breath pacer
class _GuidanceModalContent extends StatefulWidget {
  final String actId;
  final String title;
  final String category;
  final String duration;
  final String difficulty;
  final String description;
  final String rationale;
  final List<String> instructions;
  final bool isBreathingActivity;
  final bool isCompleted;
  final VoidCallback onComplete;

  const _GuidanceModalContent({
    required this.actId,
    required this.title,
    required this.category,
    required this.duration,
    required this.difficulty,
    required this.description,
    required this.rationale,
    required this.instructions,
    required this.isBreathingActivity,
    required this.isCompleted,
    required this.onComplete,
  });

  @override
  State<_GuidanceModalContent> createState() => _GuidanceModalContentState();
}

class _GuidanceModalContentState extends State<_GuidanceModalContent> {
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

  @override
  Widget build(BuildContext context) {
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

          // Header tags & close
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.category.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•  ${widget.duration}  •  ${widget.difficulty}',
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
            widget.title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Rationale Card
                  if (widget.rationale.isNotEmpty) ...[
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
                                  widget.rationale,
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
                  if (widget.isBreathingActivity) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFEEF2FF),
                            const Color(0xFFE0E7FF),
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
                                  const Icon(Icons.air, size: 16, color: Color(0xFF4F46E5)),
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
                                    _isBreathPacerActive ? 'Hentikan' : 'Mulai Pemandu',
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
                                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                border: Border.all(color: const Color(0xFF4F46E5), width: 2),
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
                    itemCount: widget.instructions.length,
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
                              widget.instructions[idx],
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
