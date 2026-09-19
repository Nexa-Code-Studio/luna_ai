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
  List<Map<String, dynamic>> _recommendations = [
    {
      'id': '1',
      'title': 'Latihan Pernapasan 4-7-8',
      'category': 'Mindfulness',
      'duration': '3 menit',
      'description':
          'Tarik napas dalam 4 detik, tahan 7 detik, lalu hembuskan perlahan 8 detik untuk meredakan ketegangan sistem saraf.',
      'icon': Icons.air,
      'iconBg': const Color(0xFFE8F5E9),
      'isCompleted': false,
    },
    {
      'id': '2',
      'title': 'Teknik Grounding 5-4-3-2-1',
      'category': 'CBT',
      'duration': '5 menit',
      'description':
          'Sadarilah 5 hal yang kamu lihat, 4 hal yang kamu sentuh, 3 suara di sekitarmu, 2 aroma, dan 1 rasa untuk kembali ke saat ini.',
      'icon': Icons.psychology,
      'iconBg': const Color(0xFFE0F7FA),
      'isCompleted': false,
    },
    {
      'id': '3',
      'title': 'Catatan Syukur Harian',
      'category': 'Refleksi',
      'duration': '3 menit',
      'description':
          'Tuliskan satu hal sederhana yang memberimu kehangatan atau kenyamanan hari ini.',
      'icon': Icons.edit_note,
      'iconBg': const Color(0xFFF3E5F5),
      'isCompleted': false,
    },
    {
      'id': '4',
      'title': 'Jalan Santai Mindful',
      'category': 'Aktivitas Fisik',
      'duration': '10 menit',
      'description':
          'Berjalan perlahan sambil memperhatikan sensasi langkah kaki dan udara di kulitmu.',
      'icon': Icons.directions_walk,
      'iconBg': const Color(0xFFFFF3E0),
      'isCompleted': false,
    },
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
        for (var r in _recommendations) {
          final rId = r['id']?.toString() ?? '';
          if (localProgress.isActivityCompleted(rId)) {
            r['isCompleted'] = true;
          }
        }
      });
      return;
    }
    try {
      final headers = await AppConfig.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/recommendations'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _recommendations = data.map((item) {
              final actId = item['id']?.toString() ?? '';
              final isDone = item['isCompleted'] == true ||
                  localProgress.isActivityCompleted(actId);
              return {
                'id': actId,
                'title': item['title'] ?? 'Rekomendasi',
                'category': item['category'] ?? 'Self-care',
                'duration': item['duration'] ?? '5 menit',
                'description': item['description'] ?? '',
                'icon': _getIconForCategory(item['category']),
                'iconBg': _getBgForCategory(item['category']),
                'isCompleted': isDone,
              };
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _completeRecommendation(String id) async {
    setState(() {
      final idx = _recommendations.indexWhere((r) => r['id'] == id);
      if (idx != -1) {
        _recommendations[idx]['isCompleted'] = true;
      }
    });

    await DailyProgressLocalService.recordActivityCompletion(id, true);

    if (AppConfig.useMockData) return;
    try {
      final headers = await AppConfig.getAuthHeaders();
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/recommendations/$id/complete'),
        headers: headers,
      );
    } catch (_) {}
  }

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'mindfulness':
        return Icons.air;
      case 'refleksi':
        return Icons.edit_note;
      case 'cbt':
        return Icons.psychology;
      default:
        return Icons.directions_walk;
    }
  }

  Color _getBgForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'mindfulness':
        return const Color(0xFF8B93FF);
      case 'refleksi':
        return const Color(0xFFC3B8FF);
      case 'cbt':
        return const Color(0xFF9EA3C0);
      default:
        return const Color(0xFF489BB8);
    }
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      color: AppColors.primary,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panduan Ketenanganmu',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Berikut beberapa saran sederhana untuk membantumu merasa lebih tenang hari ini.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Dynamic Recommendation Cards
                      ..._recommendations.map((rec) {
                        final bool isDone = rec['isCompleted'] == true;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: _buildRecCard(
                            icon: rec['icon'] as IconData,
                            iconBg: isDone ? Colors.grey : (rec['iconBg'] as Color),
                            title: rec['title'] as String,
                            subtitle: rec['description'] as String,
                            isCompleted: isDone,
                            onTap: () => _completeRecommendation(rec['id'] as String),
                          ),
                        );
                      }),
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

  Widget _buildRecCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      width: double.infinity,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
            size: isCompleted ? 20 : 16,
            color: isCompleted ? Colors.green : AppColors.textLight,
          ),
        ],
      ),
    );
  }
}
