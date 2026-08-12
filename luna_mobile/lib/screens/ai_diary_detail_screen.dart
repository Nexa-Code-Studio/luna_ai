import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/custom_button.dart';

import '../widgets/glass_card.dart';



class AiDiaryDetailScreen extends StatefulWidget {

  final Map<String, dynamic>? journalData;



  const AiDiaryDetailScreen({super.key, this.journalData});



  @override

  State<AiDiaryDetailScreen> createState() => _AiDiaryDetailScreenState();

}



class _AiDiaryDetailScreenState extends State<AiDiaryDetailScreen> {

  late String _selectedSessionId;

  bool _isInitialized = false;



  @override

  void didChangeDependencies() {

    super.didChangeDependencies();

    if (!_isInitialized) {

      final args = widget.journalData ??

          (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?);

      if (args != null && args['selectedSessionId'] != null) {

        _selectedSessionId = args['selectedSessionId'].toString();

      } else {

        _selectedSessionId = 'all';

      }

      _isInitialized = true;

    }

  }



  @override

  Widget build(BuildContext context) {

    // Default fallback data if passed data is null

    final args = widget.journalData ??

        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?);



    final data = args ?? {

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



    final bool hasRisk = data['riskWarning'] != null && data['riskWarning']['detected'] == true;

    final List<Map<String, dynamic>> sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);



    // Compute active 7-emotion breakdown list based on selected session

    List<Map<String, dynamic>> activeEmotions = [];

    if (_selectedSessionId == 'all') {

      activeEmotions = [

        {'name': 'fear', 'label': 'Takut / Gelisah', 'emoji': '😨', 'percent': 0.45, 'color': const Color(0xFF6C63FF)},

        {'name': 'sadness', 'label': 'Sedih / Haru', 'emoji': '😔', 'percent': 0.25, 'color': const Color(0xFF8B93FF)},

        {'name': 'netral', 'label': 'Netral', 'emoji': '😐', 'percent': 0.15, 'color': const Color(0xFFA7E6FF)},

        {'name': 'happy', 'label': 'Bahagia', 'emoji': '😃', 'percent': 0.10, 'color': const Color(0xFFFFE6A7)},

        {'name': 'surprise', 'label': 'Terkejut', 'emoji': '😲', 'percent': 0.03, 'color': const Color(0xFFC3B8FF)},

        {'name': 'anger', 'label': 'Marah', 'emoji': '😡', 'percent': 0.01, 'color': const Color(0xFFFFB6C1)},

        {'name': 'disgusted', 'label': 'Jijik / Muak', 'emoji': '🤢', 'percent': 0.01, 'color': const Color(0xFFB8C2FC)},

      ];

    } else {

      final selectedSessData = sessions.firstWhere(

        (s) => s['id'] == _selectedSessionId,

        orElse: () => sessions.first,

      );

      activeEmotions = List<Map<String, dynamic>>.from(selectedSessData['emotionsBreakdown']);

    }



    // Compute active transcripts list based on selected session

    List<Map<String, dynamic>> activeTranscripts = [];

    if (_selectedSessionId == 'all') {

      for (var s in sessions) {

        final tList = List<Map<String, dynamic>>.from(s['transcripts']);

        for (var t in tList) {

          activeTranscripts.add({

            ...t,

            'sessionTitle': s['title'],

          });

        }

      }

    } else {

      final selectedSessData = sessions.firstWhere(

        (s) => s['id'] == _selectedSessionId,

        orElse: () => sessions.first,

      );

      final tList = List<Map<String, dynamic>>.from(selectedSessData['transcripts']);

      for (var t in tList) {

        activeTranscripts.add({

          ...t,

          'sessionTitle': selectedSessData['title'],

        });

      }

    }



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

              // Header Bar with Back Button

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),

                child: Row(

                  children: [

                    IconButton(

                      icon: const Icon(Icons.arrow_back),

                      color: AppColors.textPrimary,

                      onPressed: () => Navigator.pop(context),

                    ),

                    const SizedBox(width: 4),

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text(

                            data['title'],

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: GoogleFonts.inter(

                              fontSize: 16,

                              fontWeight: FontWeight.w800,

                              color: AppColors.textPrimary,

                            ),

                          ),

                          Text(

                            '${data['date']} • ${sessions.length} Sesi Suara',

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: GoogleFonts.inter(

                              fontSize: 12,

                              color: AppColors.textSecondary,

                            ),

                          ),

                        ],

                      ),

                    ),

                    const SizedBox(width: 8),

                    Container(

                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

                      decoration: BoxDecoration(

                        color: const Color(0xFFEADBFF),

                        borderRadius: BorderRadius.circular(999),

                      ),

                      child: Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          Text(data['moodEmoji'], style: const TextStyle(fontSize: 14)),

                          const SizedBox(width: 4),

                          Text(

                            data['moodTag'],

                            style: GoogleFonts.inter(

                              fontSize: 11,

                              fontWeight: FontWeight.w600,

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



              // Main Body Content

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      // MENTAL HEALTH ALERT CARD (If Risk Detected)

                      if (hasRisk) ...[

                        Container(

                          width: double.infinity,

                          padding: const EdgeInsets.all(20),

                          decoration: BoxDecoration(

                            color: const Color(0xFFFFF0F2),

                            borderRadius: BorderRadius.circular(24),

                            border: Border.all(

                              color: const Color(0xFFE57373).withValues(alpha: 0.4),

                              width: 1.5,

                            ),

                            boxShadow: [

                              BoxShadow(

                                color: const Color(0xFFE57373).withValues(alpha: 0.1),

                                blurRadius: 16,

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

                                    decoration: BoxDecoration(

                                      color: const Color(0xFFFFDCDD),

                                      borderRadius: BorderRadius.circular(12),

                                    ),

                                    child: const Icon(

                                      Icons.warning_amber_rounded,

                                      color: Color(0xFFD32F2F),

                                      size: 22,

                                    ),

                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(

                                    child: Column(

                                      crossAxisAlignment: CrossAxisAlignment.start,

                                      children: [

                                        Text(

                                          data['riskWarning']['title'],

                                          maxLines: 1,

                                          overflow: TextOverflow.ellipsis,

                                          style: GoogleFonts.inter(

                                            fontSize: 14,

                                            fontWeight: FontWeight.w800,

                                            color: const Color(0xFFD32F2F),

                                          ),

                                        ),

                                        Text(

                                          'Tingkat: ${data['riskWarning']['level']}',

                                          style: GoogleFonts.inter(

                                            fontSize: 12,

                                            fontWeight: FontWeight.w600,

                                            color: const Color(0xFFE57373),

                                          ),

                                        ),

                                      ],

                                    ),

                                  ),

                                ],

                              ),

                              const SizedBox(height: 12),

                              Text(

                                data['riskWarning']['message'],

                                style: GoogleFonts.inter(

                                  fontSize: 13,

                                  color: AppColors.textPrimary,

                                  height: 1.4,

                                ),

                              ),

                              const SizedBox(height: 16),

                              Row(

                                children: [

                                  Expanded(

                                    child: CustomPillButton(

                                      text: 'Bantuan Krisis',

                                      height: 44,

                                      onPressed: () {

                                        Navigator.pushNamed(context, '/support');

                                      },

                                    ),

                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(

                                    child: CustomPillButton(

                                      text: 'Latihan Ketenangan',

                                      isOutline: true,

                                      height: 44,

                                      onPressed: () {

                                        Navigator.pushNamed(context, '/recommendation');

                                      },

                                    ),

                                  ),

                                ],

                              ),

                            ],

                          ),

                        ),

                        const SizedBox(height: 20),

                      ],



                      // 1. WAWASAN AI KUMULATIF

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              children: [

                                Container(

                                  width: 36,

                                  height: 36,

                                  decoration: BoxDecoration(

                                    color: AppColors.primary,

                                    borderRadius: BorderRadius.circular(12),

                                  ),

                                  child: const Icon(

                                    Icons.auto_awesome,

                                    color: Colors.white,

                                    size: 20,

                                  ),

                                ),

                                const SizedBox(width: 10),

                                Expanded(

                                  child: Column(

                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [

                                      Text(

                                        'WAWASAN AI KUMULATIF',

                                        style: GoogleFonts.inter(

                                          fontSize: 12,

                                          fontWeight: FontWeight.w700,

                                          color: AppColors.primary,

                                          letterSpacing: 0.8,

                                        ),

                                      ),

                                      Text(

                                        '✨ Diperbarui setelah Sesi #${sessions.length} (${data['lastSessionTime']})',

                                        style: GoogleFonts.inter(

                                          fontSize: 11,

                                          fontWeight: FontWeight.w600,

                                          color: AppColors.textSecondary,

                                        ),

                                      ),

                                    ],

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 14),

                            Text(

                              data['aiInsight'],

                              style: GoogleFonts.inter(

                                fontSize: 14,

                                color: AppColors.textPrimary,

                                height: 1.5,

                              ),

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 16),



                      // 2. PERISTIWA PENTING KUMULATIF

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              children: [

                                Container(

                                  width: 36,

                                  height: 36,

                                  decoration: BoxDecoration(

                                    color: const Color(0xFF489BB8),

                                    borderRadius: BorderRadius.circular(12),

                                  ),

                                  child: const Icon(

                                    Icons.calendar_today_outlined,

                                    color: Colors.white,

                                    size: 18,

                                  ),

                                ),

                                const SizedBox(width: 10),

                                Text(

                                  'PERISTIWA PENTING HARIAN',

                                  style: GoogleFonts.inter(

                                    fontSize: 12,

                                    fontWeight: FontWeight.w700,

                                    color: const Color(0xFF20667B),

                                    letterSpacing: 0.8,

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 14),

                            ...List<Widget>.from(

                              (data['importantEvents'] as List).map(

                                (item) => Padding(

                                  padding: const EdgeInsets.only(bottom: 8.0),

                                  child: Row(

                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [

                                      Container(

                                        margin: const EdgeInsets.only(top: 6),

                                        width: 6,

                                        height: 6,

                                        decoration: const BoxDecoration(

                                          shape: BoxShape.circle,

                                          color: AppColors.primary,

                                        ),

                                      ),

                                      const SizedBox(width: 10),

                                      Expanded(

                                        child: Text(

                                          item.toString(),

                                          style: GoogleFonts.inter(

                                            fontSize: 14,

                                            color: AppColors.textPrimary,

                                          ),

                                        ),

                                      ),

                                    ],

                                  ),

                                ),

                              ),

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 16),



                      // 3. REFLEKSI EMOSIONAL

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              children: [

                                Container(

                                  width: 36,

                                  height: 36,

                                  decoration: BoxDecoration(

                                    color: const Color(0xFF605A79),

                                    borderRadius: BorderRadius.circular(12),

                                  ),

                                  child: const Icon(

                                    Icons.psychology_outlined,

                                    color: Colors.white,

                                    size: 20,

                                  ),

                                ),

                                const SizedBox(width: 10),

                                Text(

                                  'REFLEKSI EMOSIONAL HARIAN',

                                  style: GoogleFonts.inter(

                                    fontSize: 12,

                                    fontWeight: FontWeight.w700,

                                    color: const Color(0xFF605A79),

                                    letterSpacing: 0.8,

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 14),

                            Text(

                              data['emotionalReflection'],

                              style: GoogleFonts.inter(

                                fontSize: 14,

                                color: AppColors.textPrimary,

                                height: 1.5,

                              ),

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 24),



                      // SESSION SELECTOR CHIPS SECTION

                      Text(

                        'PILIH SESI UNTUK PENGURAIAN SPESIFIK',

                        style: GoogleFonts.inter(

                          fontSize: 11,

                          fontWeight: FontWeight.w700,

                          color: AppColors.textLight,

                          letterSpacing: 0.8,

                        ),

                      ),

                      const SizedBox(height: 10),

                      SizedBox(

                        height: 38,

                        child: ListView(

                          scrollDirection: Axis.horizontal,

                          children: [

                            ChoiceChip(

                              showCheckmark: false,

                              label: Text('Semua Sesi (${sessions.length})'),

                              selected: _selectedSessionId == 'all',

                              selectedColor: AppColors.primaryContainer,

                              backgroundColor: Colors.white.withValues(alpha: 0.9),

                              labelStyle: GoogleFonts.inter(

                                fontSize: 12,

                                fontWeight: _selectedSessionId == 'all' ? FontWeight.w700 : FontWeight.w500,

                                color: _selectedSessionId == 'all' ? AppColors.primary : AppColors.textSecondary,

                              ),

                              shape: RoundedRectangleBorder(

                                borderRadius: BorderRadius.circular(999),

                                side: BorderSide(

                                  color: _selectedSessionId == 'all' ? AppColors.primary : Colors.transparent,

                                ),

                              ),

                              onSelected: (_) => setState(() => _selectedSessionId = 'all'),

                            ),

                            const SizedBox(width: 8),

                            ...sessions.map((sess) {

                              final isSel = sess['id'] == _selectedSessionId;

                              return Padding(

                                padding: const EdgeInsets.only(right: 8.0),

                                child: ChoiceChip(

                                  showCheckmark: false,

                                  label: Text('${sess['moodEmoji']} ${sess['time']}'),

                                  selected: isSel,

                                  selectedColor: AppColors.primaryContainer,

                                  backgroundColor: Colors.white.withValues(alpha: 0.9),

                                  labelStyle: GoogleFonts.inter(

                                    fontSize: 12,

                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,

                                    color: isSel ? AppColors.primary : AppColors.textSecondary,

                                  ),

                                  shape: RoundedRectangleBorder(

                                    borderRadius: BorderRadius.circular(999),

                                    side: BorderSide(

                                      color: isSel ? AppColors.primary : Colors.transparent,

                                    ),

                                  ),

                                  onSelected: (_) => setState(() => _selectedSessionId = sess['id']),

                                ),

                              );

                            }),

                          ],

                        ),

                      ),

                      const SizedBox(height: 20),



                      // 4. ANALISIS EMOSI PER SESI (7 Parameter Emosi Filtered)

                      Row(

                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [

                          Text(

                            'ANALISIS 7 PARAMETER EMOSI',

                            style: GoogleFonts.inter(

                              fontSize: 11,

                              fontWeight: FontWeight.w700,

                              color: AppColors.textLight,

                              letterSpacing: 0.8,

                            ),

                          ),

                          Container(

                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

                            decoration: BoxDecoration(

                              color: const Color(0xFFEADBFF),

                              borderRadius: BorderRadius.circular(999),

                            ),

                            child: Text(

                              _selectedSessionId == 'all' ? 'KUMULATIF' : 'SESI SPESIFIK',

                              style: GoogleFonts.inter(

                                fontSize: 9,

                                fontWeight: FontWeight.w800,

                                color: AppColors.primary,

                              ),

                            ),

                          ),

                        ],

                      ),

                      const SizedBox(height: 10),

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Column(

                          children: activeEmotions.map((emo) {

                            final double pct = (emo['percent'] as num).toDouble();

                            final int pctInt = (pct * 100).round();

                            return Padding(

                              padding: const EdgeInsets.only(bottom: 12.0),

                              child: Column(

                                children: [

                                  Row(

                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                    children: [

                                      Row(

                                        children: [

                                          Text(emo['emoji'], style: const TextStyle(fontSize: 16)),

                                          const SizedBox(width: 8),

                                          Text(

                                            emo['label'],

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

                                          fontWeight: FontWeight.w700,

                                          color: AppColors.primary,

                                        ),

                                      ),

                                    ],

                                  ),

                                  const SizedBox(height: 6),

                                  ClipRRect(

                                    borderRadius: BorderRadius.circular(999),

                                    child: LinearProgressIndicator(

                                      value: pct,

                                      minHeight: 7,

                                      backgroundColor: const Color(0xFFE2E4F0),

                                      valueColor: AlwaysStoppedAnimation<Color>(emo['color']),

                                    ),

                                  ),

                                ],

                              ),

                            );

                          }).toList(),

                        ),

                      ),

                      const SizedBox(height: 20),



                      // 5. TRANSKRIP PERCAKAPAN SUARA (Voice-to-Text Filtered with overflow protection)

                      Row(

                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [

                          Text(

                            'TRANSKRIP PERCAKAPAN SUARA',

                            style: GoogleFonts.inter(

                              fontSize: 11,

                              fontWeight: FontWeight.w700,

                              color: AppColors.textLight,

                              letterSpacing: 0.8,

                            ),

                          ),

                          Text(

                            '${activeTranscripts.length} Percakapan',

                            style: GoogleFonts.inter(

                              fontSize: 11,

                              color: AppColors.textSecondary,

                            ),

                          ),

                        ],

                      ),

                      const SizedBox(height: 10),

                      ListView.builder(

                        shrinkWrap: true,

                        physics: const NeverScrollableScrollPhysics(),

                        itemCount: activeTranscripts.length,

                        itemBuilder: (context, index) {

                          final item = activeTranscripts[index];

                          final bool isUser = item['isUser'] as bool;

                          return Container(

                            margin: const EdgeInsets.only(bottom: 12),

                            padding: const EdgeInsets.all(16),

                            decoration: BoxDecoration(

                              color: isUser

                                  ? const Color(0xFFF0F2FF)

                                  : Colors.white.withValues(alpha: 0.9),

                              borderRadius: BorderRadius.circular(16),

                              border: Border.all(

                                color: isUser

                                    ? AppColors.primary.withValues(alpha: 0.2)

                                    : Colors.grey.shade200,

                              ),

                            ),

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Row(

                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                                  children: [

                                    Text(

                                      isUser ? 'Pengguna' : 'LUNA AI',

                                      style: GoogleFonts.inter(

                                        fontSize: 12,

                                        fontWeight: FontWeight.w700,

                                        color: isUser ? AppColors.primary : const Color(0xFF20667B),

                                      ),

                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(

                                      child: Row(

                                        mainAxisAlignment: MainAxisAlignment.end,

                                        children: [

                                          if (isUser && item['emotionTag'] != null) ...[

                                            Text(item['emotionEmoji'] ?? '', style: const TextStyle(fontSize: 12)),

                                            const SizedBox(width: 4),

                                            Flexible(

                                              child: Container(

                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

                                                decoration: BoxDecoration(

                                                  color: const Color(0xFFEADBFF),

                                                  borderRadius: BorderRadius.circular(999),

                                                ),

                                                child: Text(

                                                  item['emotionTag'],

                                                  maxLines: 1,

                                                  overflow: TextOverflow.ellipsis,

                                                  style: GoogleFonts.inter(

                                                    fontSize: 10,

                                                    fontWeight: FontWeight.w700,

                                                    color: AppColors.primary,

                                                  ),

                                                ),

                                              ),

                                            ),

                                            const SizedBox(width: 6),

                                          ],

                                          Text(

                                            item['time'],

                                            style: GoogleFonts.inter(

                                              fontSize: 11,

                                              color: AppColors.textLight,

                                            ),

                                          ),

                                        ],

                                      ),

                                    ),

                                  ],

                                ),

                                const SizedBox(height: 8),

                                Text(

                                  item['text'],

                                  style: GoogleFonts.inter(

                                    fontSize: 13,

                                    color: AppColors.textPrimary,

                                    height: 1.4,

                                  ),

                                ),

                              ],

                            ),

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

}

