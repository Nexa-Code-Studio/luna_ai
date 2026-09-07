import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    if (AppConfig.useMockData) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/recommendations'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _recommendations = data.map((item) {
              return {
                'id': item['id'] ?? '',
                'title': item['title'] ?? 'Rekomendasi',
                'category': item['category'] ?? 'Self-care',
                'duration': item['duration'] ?? '5 menit',
                'description': item['description'] ?? '',
                'icon': _getIconForCategory(item['category']),
                'iconBg': _getBgForCategory(item['category']),
                'isCompleted': item['isCompleted'] ?? false,
              };
            }).toList();
          });
        }
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeRecommendation(String id) async {
    setState(() {
      final idx = _recommendations.indexWhere((r) => r['id'] == id);
      if (idx != -1) {
        _recommendations[idx]['isCompleted'] = true;
      }
    });

    if (AppConfig.useMockData) return;
    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/recommendations/$id/complete'),
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
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_recommendations.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                const Icon(Icons.auto_awesome_outlined, size: 48, color: Color(0xFFBDBDBD)),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada rekomendasi untukmu',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF767684),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Rekomendasi akan muncul setelah kamu berdialog bersama LUNA.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9EA0AB)),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
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
