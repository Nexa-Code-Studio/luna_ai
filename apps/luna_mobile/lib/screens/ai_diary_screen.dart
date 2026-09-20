import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';



class AiDiaryScreen extends StatefulWidget {
  const AiDiaryScreen({super.key});

  @override
  State<AiDiaryScreen> createState() => AiDiaryScreenState();
}

class AiDiaryScreenState extends State<AiDiaryScreen> {

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



  late List<Map<String, dynamic>> _entries;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entries = [];
    _fetchRemoteDiaries();
  }

  void refresh() => _fetchRemoteDiaries();

  Future<void> _fetchRemoteDiaries() async {
    if (AppConfig.useMockData) {
      if (mounted) {
        setState(() {
          _entries = [];
          _isLoading = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    try {
      final headers = await AppConfig.getAuthHeaders();
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrl}/diaries'), headers: headers)
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _entries = data.map((e) => Map<String, dynamic>.from(e)).toList();
          });
        }
      }
    } catch (_) {
      // Keep existing entries or empty
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filteredList = _entries.where((item) {
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

                  ],

                ),

              ),



              // Scrollable Main Content
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _fetchRemoteDiaries,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),

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

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(
                            color: AppColors.primary,
                            minHeight: 2.5,
                          ),
                        ),

                      // Journal History Cards List

                      if (filteredList.isEmpty)
                        if (_entries.isEmpty && !_isLoading)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_outlined,
                                      size: 42,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum Ada Jurnal Refleksi',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ceritakan harimu atau lakukan panggilan suara dengan LUNA. Setelah sesi selesai, jurnal refleksi emosimu akan otomatis tersintesis dan tersimpan di sini.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textLight,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/call');
                                    },
                                    icon: const Icon(Icons.phone_in_talk, size: 18),
                                    label: const Text('Mulai Bicara dengan LUNA'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
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
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEADBFF),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            item['moodTag'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
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
              ),

            ],

          ),

        ),

      ),

    );

  }

}

