import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_card.dart';

class AiConversationScreen extends StatefulWidget {
  const AiConversationScreen({super.key});

  @override
  State<AiConversationScreen> createState() => _AiConversationScreenState();
}

class _AiConversationScreenState extends State<AiConversationScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    setState(() => _isLoading = true);
    try {
      final headers = await AppConfig.getAuthHeaders();
      final res = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/conversations'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _conversations = List<Map<String, dynamic>>.from(data);
          });
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
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

                    const Spacer(),

                    Container(

                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                      decoration: BoxDecoration(

                        color: AppColors.primaryContainer,

                        borderRadius: BorderRadius.circular(999),

                      ),

                      child: Row(

                        children: [

                          Container(

                            width: 6,

                            height: 6,

                            decoration: const BoxDecoration(

                              shape: BoxShape.circle,

                              color: Color(0xFF4CAF50),

                            ),

                          ),

                          const SizedBox(width: 6),

                          Text(

                            'MODE SUARA AI',

                            style: GoogleFonts.inter(

                              fontSize: 10,

                              fontWeight: FontWeight.w700,

                              color: AppColors.primary,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

              ),

              const Divider(height: 1, color: Color(0xFFEBECEF)),



              // Scrollable Content Body

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),

                  child: Column(

                    children: [

                      const SizedBox(height: 12),



                      // 3D Glowing Iridescent Orb Visual

                      Center(

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

                      const SizedBox(height: 28),



                      // Title & Subtitle Greeting

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

                      const SizedBox(height: 32),



                      // Main Action Button: Mulai Sesi Suara
                      CustomPillButton(
                        text: 'Mulai Sesi Suara',
                        suffixIcon: Icons.mic,
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/voice_call');
                          if (mounted) {
                            _fetchConversations();
                          }
                        },
                      ),
                      const SizedBox(height: 36),

                      // Recent Voice Sessions Section
                      Align(
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
                      const SizedBox(height: 12),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_conversations.isNotEmpty)
                        ..._conversations.map((conv) {
                          final title = conv['title']?.toString() ?? 'Sesi Percakapan LUNA';
                          final time = conv['lastMessageTime']?.toString() ?? 'Hari ini';
                          final msgs = conv['messages'] as List? ?? [];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildSessionHistoryCard(
                              title: title,
                              duration: '04:00',
                              date: time,
                              moodTag: 'Sesi Suara',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/diary_detail',
                                  arguments: {
                                    'title': title,
                                    'date': time,
                                    'sessionCount': 1,
                                    'lastSessionTime': time,
                                    'moodTag': 'Mendengarkan',
                                    'moodEmoji': '🌱',
                                    'summary': conv['lastMessage']?.toString() ??
                                        'Sesi percakapan curhat bersama LUNA.',
                                    'riskWarning': {'detected': false},
                                    'aiInsight':
                                        'Percakapan berhasil disintesis dan diproses untuk pemantauan kesehatan emosionalmu.',
                                    'importantEvents': ['Sesi percakapan aktif selesai tercatat'],
                                    'emotionalReflection':
                                        'Emosi terartikulasi secara positif melalui sesi curhat bersama AI.',
                                    'sessions': [
                                      {
                                        'id': conv['id'] ?? 's1',
                                        'title': title,
                                        'time': time,
                                        'moodTag': 'Mendengarkan',
                                        'moodEmoji': '✨',
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
                                            .map((m) => {
                                                  'isUser': m['sender'] == 'user',
                                                  'time': m['time'] ?? '',
                                                  'text': m['text'] ?? '',
                                                  'emotionTag':
                                                      m['sender'] == 'user' ? 'Refleksi' : '',
                                                  'emotionEmoji':
                                                      m['sender'] == 'user' ? '🌱' : '',
                                                })
                                            .toList(),
                                      }
                                    ],
                                    'selectedSessionId': conv['id'] ?? 's1',
                                  },
                                );
                              },
                            ),
                          );
                        })
                      else if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        Padding(
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



  Widget _buildSessionHistoryCard({

    required String title,

    required String duration,

    required String date,

    required String moodTag,

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

            child: const Icon(

              Icons.volume_up_outlined,

              color: AppColors.primary,

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

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

            decoration: BoxDecoration(

              color: const Color(0xFFEADBFF),

              borderRadius: BorderRadius.circular(999),

            ),

            child: Text(

              moodTag,

              style: GoogleFonts.inter(

                fontSize: 11,

                fontWeight: FontWeight.w600,

                color: AppColors.primary,

              ),

            ),

          ),

        ],

      ),

    );

  }

}

