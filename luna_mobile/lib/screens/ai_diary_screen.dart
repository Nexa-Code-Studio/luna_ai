import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/glass_card.dart';



class AiDiaryScreen extends StatefulWidget {

  const AiDiaryScreen({super.key});



  @override

  State<AiDiaryScreen> createState() => _AiDiaryScreenState();

}



class _AiDiaryScreenState extends State<AiDiaryScreen> {

  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'Semua';



  final List<String> _filterCategories = const [

    'Semua',

    'Tenang 😌',

    'Cemas 😰',

    'Bahagia 😃',

    'Sedih 😔',

    'Stres 💥',

  ];



  final List<Map<String, dynamic>> _journalEntries = const [

    {

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

    },

    {

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

              'text': 'Luar biasa Sarah! Selamat atas pencapaian gemilang ini!',

            },

          ],

        },

      ],

    },

  ];



  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final query = _searchController.text.toLowerCase();

    final filteredList = _journalEntries.where((item) {

      final matchesQuery = query.isEmpty ||

          item['title'].toString().toLowerCase().contains(query) ||

          item['summary'].toString().toLowerCase().contains(query) ||

          item['moodTag'].toString().toLowerCase().contains(query);



      final matchesFilter = _selectedFilter == 'Semua' ||

          item['moodTag'].toString().toLowerCase().contains(_selectedFilter.split(' ').first.toLowerCase());



      return matchesQuery && matchesFilter;

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

              // Header Bar with Settings Gear Icon

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



              // Scrollable Main Content

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      // Title Header

                      Text(

                        'Jurnal AI Harian & Sesi',

                        style: GoogleFonts.inter(

                          fontSize: 24,

                          fontWeight: FontWeight.w800,

                          color: AppColors.textPrimary,

                        ),

                      ),

                      const SizedBox(height: 4),

                      Text(

                        'Hasil analisis kumulatif harian dan transkrip per sesi percakapan suara bersama LUNA.',

                        style: GoogleFonts.inter(

                          fontSize: 13,

                          color: AppColors.textSecondary,

                          height: 1.4,

                        ),

                      ),

                      const SizedBox(height: 20),



                      // Search Bar Field

                      Container(

                        decoration: BoxDecoration(

                          color: Colors.white.withValues(alpha: 0.9),

                          borderRadius: BorderRadius.circular(999),

                          boxShadow: [

                            BoxShadow(

                              color: Colors.black.withValues(alpha: 0.04),

                              blurRadius: 16,

                              offset: const Offset(0, 4),

                            ),

                          ],

                        ),

                        child: TextField(

                          controller: _searchController,

                          onChanged: (_) => setState(() {}),

                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),

                          decoration: InputDecoration(

                            hintText: 'Cari jurnal atau kata kunci emosi...',

                            hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),

                            prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),

                            suffixIcon: query.isNotEmpty

                                ? IconButton(

                                    icon: const Icon(Icons.clear, size: 18),

                                    onPressed: () {

                                      _searchController.clear();

                                      setState(() {});

                                    },

                                  )

                                : null,

                            border: InputBorder.none,

                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                          ),

                        ),

                      ),

                      const SizedBox(height: 16),



                      // Filter Category Chips

                      SizedBox(

                        height: 38,

                        child: ListView.separated(

                          scrollDirection: Axis.horizontal,

                          itemCount: _filterCategories.length,

                          separatorBuilder: (context, index) => const SizedBox(width: 8),

                          itemBuilder: (context, index) {

                            final category = _filterCategories[index];

                            final isSelected = category == _selectedFilter;

                            return ChoiceChip(

                              showCheckmark: false,

                              label: Text(category),

                              selected: isSelected,

                              selectedColor: AppColors.primaryContainer,

                              backgroundColor: Colors.white.withValues(alpha: 0.8),

                              labelStyle: GoogleFonts.inter(

                                fontSize: 12,

                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,

                                color: isSelected ? AppColors.primary : AppColors.textSecondary,

                              ),

                              shape: RoundedRectangleBorder(

                                borderRadius: BorderRadius.circular(999),

                                side: BorderSide(

                                  color: isSelected ? AppColors.primary : Colors.transparent,

                                ),

                              ),

                              onSelected: (selected) {

                                setState(() {

                                  _selectedFilter = category;

                                });

                              },

                            );

                          },

                        ),

                      ),

                      const SizedBox(height: 20),



                      // Journal History Cards List

                      if (filteredList.isEmpty)

                        Center(

                          child: Padding(

                            padding: const EdgeInsets.symmetric(vertical: 40.0),

                            child: Column(

                              children: [

                                const Icon(Icons.search_off, size: 48, color: AppColors.textLight),

                                const SizedBox(height: 12),

                                Text(

                                  'Tidak ada jurnal yang sesuai',

                                  style: GoogleFonts.inter(

                                    fontSize: 14,

                                    fontWeight: FontWeight.w600,

                                    color: AppColors.textSecondary,

                                  ),

                                ),

                              ],

                            ),

                          ),

                        )

                      else

                        ListView.separated(

                          shrinkWrap: true,

                          physics: const NeverScrollableScrollPhysics(),

                          itemCount: filteredList.length,

                          separatorBuilder: (context, index) => const SizedBox(width: 0, height: 14),

                          itemBuilder: (context, index) {

                            final item = filteredList[index];

                            final hasRisk = item['riskWarning'] != null &&

                                item['riskWarning']['detected'] == true;

                            final sessionCount = item['sessionCount'] ?? 1;



                            return GlassCard(

                              width: double.infinity,

                              onTap: () {

                                Navigator.pushNamed(

                                  context,

                                  '/diary_detail',

                                  arguments: item,

                                );

                              },

                              padding: const EdgeInsets.all(18),

                              child: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [

                                  Row(

                                    children: [

                                      Text(item['moodEmoji'], style: const TextStyle(fontSize: 18)),

                                      const SizedBox(width: 8),

                                      Expanded(

                                        child: Text(

                                          item['title'],

                                          maxLines: 1,

                                          overflow: TextOverflow.ellipsis,

                                          style: GoogleFonts.inter(

                                            fontSize: 15,

                                            fontWeight: FontWeight.w700,

                                            color: AppColors.textPrimary,

                                          ),

                                        ),

                                      ),

                                      const SizedBox(width: 8),

                                      const Icon(

                                        Icons.arrow_forward_ios,

                                        size: 14,

                                        color: AppColors.textLight,

                                      ),

                                    ],

                                  ),

                                  const SizedBox(height: 6),

                                  Wrap(

                                    crossAxisAlignment: WrapCrossAlignment.center,

                                    spacing: 8,

                                    runSpacing: 4,

                                    children: [

                                      Text(

                                        item['date'],

                                        style: GoogleFonts.inter(

                                          fontSize: 12,

                                          color: AppColors.textLight,

                                        ),

                                      ),

                                      Container(

                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

                                        decoration: BoxDecoration(

                                          color: AppColors.primaryContainer,

                                          borderRadius: BorderRadius.circular(999),

                                        ),

                                        child: Text(

                                          '🎙️ $sessionCount SESI SUARA',

                                          style: GoogleFonts.inter(

                                            fontSize: 9,

                                            fontWeight: FontWeight.w800,

                                            color: AppColors.primary,

                                          ),

                                        ),

                                      ),

                                      if (hasRisk)

                                        Container(

                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

                                          decoration: BoxDecoration(

                                            color: const Color(0xFFFFDCDD),

                                            borderRadius: BorderRadius.circular(999),

                                          ),

                                          child: Text(

                                            '⚠️ PERINGATAN MENTAL HEALTH',

                                            style: GoogleFonts.inter(

                                              fontSize: 9,

                                              fontWeight: FontWeight.w800,

                                              color: const Color(0xFFD32F2F),

                                            ),

                                          ),

                                        ),

                                    ],

                                  ),

                                  const SizedBox(height: 10),

                                  Text(

                                    item['summary'],

                                    maxLines: 2,

                                    overflow: TextOverflow.ellipsis,

                                    style: GoogleFonts.inter(

                                      fontSize: 13,

                                      color: AppColors.textSecondary,

                                      height: 1.4,

                                    ),

                                  ),

                                  const SizedBox(height: 12),

                                  Row(

                                    children: [

                                      Container(

                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                                        decoration: BoxDecoration(

                                          color: const Color(0xFFEADBFF),

                                          borderRadius: BorderRadius.circular(999),

                                        ),

                                        child: Text(

                                          item['moodTag'],

                                          style: GoogleFonts.inter(

                                            fontSize: 11,

                                            fontWeight: FontWeight.w600,

                                            color: AppColors.primary,

                                          ),

                                        ),

                                      ),

                                      const Spacer(),

                                      Text(

                                        'Lihat Detail Sesi →',

                                        style: GoogleFonts.inter(

                                          fontSize: 12,

                                          fontWeight: FontWeight.w700,

                                          color: AppColors.primary,

                                        ),

                                      ),

                                    ],

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

