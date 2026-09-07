import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/custom_button.dart';

import '../widgets/glass_card.dart';



class AiConversationScreen extends StatelessWidget {

  const AiConversationScreen({super.key});



  @override

  Widget build(BuildContext context) {

    final sampleEntry1 = {

      'id': '1',

      'title': 'Refleksi Harian & Evaluasi Ujian',

      'date': '24 Oktober 2023',

      'sessionCount': 3,

      'lastSessionTime': '21:45 PM',

      'moodTag': 'Cemas & Stres',

      'moodEmoji': '😰',

      'summary':

          'Kumulatif 3 sesi suara hari ini: Refleksi Pagi (kecemasan akademik), Curhat Sore (istirahat teh), dan Refleksi Malam (evaluasi jadwal). LUNA menyintesis kemajuan emosional harianmu.',

      'riskWarning': {

        'detected': true,

        'type': 'anxiety',

        'title': 'Indikasi Anxiety & Stres Kumulatif Terdeteksi',

        'level': 'Tinggi (68%)',

        'message':

            'LUNA mendeteksi akumulasi kecemasan dan stres pada 3 sesi percakapan hari ini. Jangan ragu mengambil waktu jeda istirahat.',

      },

      'aiInsight':

          'Kumulatif Hari Ini: Meskipun beban akademik memicu akumulasi rasa cemas pada Sesi #1 dan Sesi #3, kamu berhasil menenangkan diri pada Sesi #2 saat istirahat teh.',

      'importantEvents': [

        '[Sesi #1 - 09:15 AM] Sesi belajar pagi & kecemasan ujian tengah semester',

        '[Sesi #2 - 16:30 PM] Minum teh hangat & jeda santai',

        '[Sesi #3 - 21:45 PM] Mengatur ulang target jadwal perkuliahan',

      ],

      'emotionalReflection':

          'Dinamika harian menunjukkan fluktuasi dari kecemasan tinggi di pagi hari, mereda di sore hari, dan kembali reflektif di malam hari.',

      'sessions': [

        {

          'id': 's1',

          'title': 'Sesi #1: Refleksi Pagi & Ujian',

          'time': '09:15 AM',

          'moodTag': 'Takut & Cemas',

          'moodEmoji': '😨',

          'emotionsBreakdown': [

            {'name': 'fear', 'label': 'Takut / Gelisah', 'emoji': '😨', 'percent': 0.65, 'color': Color(0xFF6C63FF)},

            {'name': 'sadness', 'label': 'Sedih / Haru', 'emoji': '😔', 'percent': 0.20, 'color': Color(0xFF8B93FF)},

            {'name': 'netral', 'label': 'Netral', 'emoji': '😐', 'percent': 0.15, 'color': Color(0xFFA7E6FF)},

          ],

          'transcripts': [

            {

              'isUser': true,

              'time': '09:15 AM',

              'text': 'Saya sangat cemas dan takut tidak bisa menyelesaikan tugas kuliah ini dengan baik.',

              'emotionTag': 'fear (68%)',

              'emotionEmoji': '😨',

            },

            {

              'isUser': false,

              'time': '09:16 AM',

              'text':

                  'Aku mendengarmu, Sarah. Sangat wajar merasa cemas saat tugas menumpuk. Mari kita uraikan bersama menjadi langkah kecil ya.',

            },

          ],

        },

        {

          'id': 's2',

          'title': 'Sesi #2: Jeda Ketenangan Sore',

          'time': '16:30 PM',

          'moodTag': 'Tenang & Nyaman',

          'moodEmoji': '😌',

          'emotionsBreakdown': [

            {'name': 'netral', 'label': 'Netral', 'emoji': '😐', 'percent': 0.50, 'color': Color(0xFFA7E6FF)},

            {'name': 'happy', 'label': 'Bahagia', 'emoji': '😃', 'percent': 0.35, 'color': Color(0xFFFFE6A7)},

            {'name': 'fear', 'label': 'Takut / Gelisah', 'emoji': '😨', 'percent': 0.15, 'color': Color(0xFF6C63FF)},

          ],

          'transcripts': [

            {

              'isUser': true,

              'time': '16:30 PM',

              'text': 'Saya baru saja minum teh dan berjalan santai sebentar. Rasanya sedikit lebih lega.',

              'emotionTag': 'netral (60%)',

              'emotionEmoji': '😐',

            },

            {

              'isUser': false,

              'time': '16:31 PM',

              'text': 'Itu langkah yang luar biasa! Memberikan waktu istirahat pada pikiran sangat penting untuk pemulihan energimu.',

            },

          ],

        },

        {

          'id': 's3',

          'title': 'Sesi #3: Evaluasi Malam & Jadwal',

          'time': '21:45 PM',

          'moodTag': 'Reflektif & Lelah',

          'moodEmoji': '😴',

          'emotionsBreakdown': [

            {'name': 'fear', 'label': 'Takut / Gelisah', 'emoji': '😨', 'percent': 0.40, 'color': Color(0xFF6C63FF)},

            {'name': 'sadness', 'label': 'Sedih / Haru', 'emoji': '😔', 'percent': 0.35, 'color': Color(0xFF8B93FF)},

            {'name': 'netral', 'label': 'Netral', 'emoji': '😐', 'percent': 0.25, 'color': Color(0xFFA7E6FF)},

          ],

          'transcripts': [

            {

              'isUser': true,

              'time': '21:45 PM',

              'text': 'Malam ini saya merapikan ulang target besok agar tidak kaget lagi.',

              'emotionTag': 'sadness (55%)',

              'emotionEmoji': '😔',

            },

            {

              'isUser': false,

              'time': '21:46 PM',

              'text': 'Langkah yang sangat bijak. Sekarang matikan gawai dan istirahatlah dengan tenang.',

            },

          ],

        },

      ],

    };



    final sampleEntry2 = {

      'id': '2',

      'title': 'Pencapaian Kerja & Kegembiraan',

      'date': '23 Oktober 2023',

      'sessionCount': 2,

      'lastSessionTime': '17:00 PM',

      'moodTag': 'Bahagia & Berenergi',

      'moodEmoji': '😃',

      'summary':

          'Kumulatif 2 sesi suara: Diskusi strategi pagi dan perayaan keberhasilan presentasi tim di sore hari.',

      'riskWarning': {'detected': false},

      'aiInsight':

          'Kumulatif Hari Ini: Energi dan motivasimu berada pada tingkat puncak. Apresiasi keberhasilan timmu!',

      'importantEvents': [

        '[Sesi #1 - 10:00 AM] Persiapan materi presentasi laporan',

        '[Sesi #2 - 17:00 PM] Perayaan sukses presentasi bersama tim',

      ],

      'emotionalReflection':

          'Persiapan matang membuahkan hasil positif yang memberi rasa kepuasan tinggi.',

      'sessions': [

        {

          'id': 's1',

          'title': 'Sesi #1: Persiapan Presentasi',

          'time': '10:00 AM',

          'moodTag': 'Fokus & Antusias',

          'moodEmoji': '😃',

          'emotionsBreakdown': [

            {'name': 'happy', 'label': 'Bahagia', 'emoji': '😃', 'percent': 0.60, 'color': Color(0xFFFFE6A7)},

            {'name': 'netral', 'label': 'Netral', 'emoji': '😐', 'percent': 0.40, 'color': Color(0xFFA7E6FF)},

          ],

          'transcripts': [

            {

              'isUser': true,

              'time': '10:00 AM',

              'text': 'Materi presentasi sudah siap 100%, mohon doanya LUNA.',

              'emotionTag': 'happy (70%)',

              'emotionEmoji': '😃',

            },

            {

              'isUser': false,

              'time': '10:01 AM',

              'text': 'Kamu sudah berusaha keras, percaya pada kemampuanmu! Semoga sukses!',

            },

          ],

        },

        {

          'id': 's2',

          'title': 'Sesi #2: Perayaan Sukses Sore',

          'time': '17:00 PM',

          'moodTag': 'Sangat Bahagia',

          'moodEmoji': '🥳',

          'emotionsBreakdown': [

            {'name': 'happy', 'label': 'Bahagia', 'emoji': '😃', 'percent': 0.85, 'color': Color(0xFFFFE6A7)},

            {'name': 'surprise', 'label': 'Terkejut', 'emoji': '😲', 'percent': 0.15, 'color': Color(0xFFC3B8FF)},

          ],

          'transcripts': [

            {

              'isUser': true,

              'time': '17:00 PM',

              'text': 'Presentasinya sukses besar! Klien sangat puas!',

              'emotionTag': 'happy (90%)',

              'emotionEmoji': '😃',

            },

            {

              'isUser': false,

              'time': '17:01 AM',

              'text': 'Selamat Sarah! Kerja kerasmu luar biasa, kamu layak merayakan momen ini.',

            },

          ],

        },

      ],

    };



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

                        onPressed: () {

                          Navigator.pushNamed(context, '/voice_call');

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



                      // History Card 1 -> Opens AiDiaryDetailScreen with session #1 active

                      _buildSessionHistoryCard(

                        title: 'Sesi Refleksi Pagi',

                        duration: '04:12',

                        date: 'Hari ini, 09:15 AM',

                        moodTag: 'Takut & Cemas',

                        onTap: () {

                          Navigator.pushNamed(

                            context,

                            '/diary_detail',

                            arguments: {

                              ...sampleEntry1,

                              'selectedSessionId': 's1',

                            },

                          );

                        },

                      ),

                      const SizedBox(height: 10),



                      // History Card 2 -> Opens AiDiaryDetailScreen with session #2 active

                      _buildSessionHistoryCard(

                        title: 'Curhat Bebas Sore Hari',

                        duration: '06:45',

                        date: 'Kemarin, 16:30 PM',

                        moodTag: 'Tenang & Nyaman',

                        onTap: () {

                          Navigator.pushNamed(

                            context,

                            '/diary_detail',

                            arguments: {

                              ...sampleEntry2,

                              'selectedSessionId': 's2',

                            },

                          );

                        },

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

