import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import 'custom_button.dart';



class MoodCheckinBottomSheet extends StatefulWidget {

  final String initialMoodLabel;

  final String initialMoodEmoji;

  final Function(String moodLabel, String moodEmoji) onSave;



  const MoodCheckinBottomSheet({

    super.key,

    required this.initialMoodLabel,

    required this.initialMoodEmoji,

    required this.onSave,

  });



  @override

  State<MoodCheckinBottomSheet> createState() => _MoodCheckinBottomSheetState();

}



class _MoodCheckinBottomSheetState extends State<MoodCheckinBottomSheet> {

  late String _selectedMoodLabel;

  late String _selectedMoodEmoji;



  final List<Map<String, String>> _moodOptions = const [

    {'emoji': '😌', 'label': 'Tenang & Damai'},

    {'emoji': '😃', 'label': 'Bahagia & Berenergi'},

    {'emoji': '😰', 'label': 'Cemas & Gelisah'},

    {'emoji': '😔', 'label': 'Sedih & Haru'},

    {'emoji': '😴', 'label': 'Lelah & Kewalahan'},

  ];



  final List<String> _triggerOptions = [

    '📚 Studi / Ujian',

    '💼 Pekerjaan',

    '💤 Kualitas Tidur',

    '👥 Hubungan',

    '🏠 Keluarga',

  ];



  final Set<String> _selectedTriggers = {'📚 Studi / Ujian'};

  final TextEditingController _noteController = TextEditingController();

  final TextEditingController _customTriggerController = TextEditingController();



  @override

  void initState() {

    super.initState();

    _selectedMoodLabel = widget.initialMoodLabel;

    _selectedMoodEmoji = widget.initialMoodEmoji;

  }



  @override

  void dispose() {

    _noteController.dispose();

    _customTriggerController.dispose();

    super.dispose();

  }



  void _showAddCustomTriggerDialog() {

    _customTriggerController.clear();

    showDialog(

      context: context,

      builder: (context) {

        return AlertDialog(

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

          title: Text(

            'Tambah Pemicu Baru',

            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),

          ),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Text(

                'Masukkan pemicu emosi kustom yang tidak ada dalam daftar.',

                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),

              ),

              const SizedBox(height: 14),

              TextField(

                controller: _customTriggerController,

                autofocus: true,

                style: GoogleFonts.inter(fontSize: 14),

                decoration: InputDecoration(

                  hintText: 'Contoh: Keuangan, Cuaca, Kesehatan',

                  hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),

                  filled: true,

                  fillColor: const Color(0xFFF4F6FF),

                  border: OutlineInputBorder(

                    borderRadius: BorderRadius.circular(16),

                    borderSide: BorderSide.none,

                  ),

                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

                ),

              ),

            ],

          ),

          actions: [

            TextButton(

              onPressed: () => Navigator.pop(context),

              child: Text(

                'Batal',

                style: GoogleFonts.inter(color: AppColors.textSecondary),

              ),

            ),

            ElevatedButton(

              style: ElevatedButton.styleFrom(

                backgroundColor: AppColors.primary,

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),

              ),

              onPressed: () {

                final text = _customTriggerController.text.trim();

                if (text.isNotEmpty) {

                  final formattedTag = '✨ $text';

                  setState(() {

                    if (!_triggerOptions.contains(formattedTag)) {

                      _triggerOptions.add(formattedTag);

                    }

                    _selectedTriggers.add(formattedTag);

                  });

                  Navigator.pop(context);

                }

              },

              child: Text(

                'Tambah',

                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),

              ),

            ),

          ],

        );

      },

    );

  }



  @override

  Widget build(BuildContext context) {

    return ClipRRect(

      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),

      child: BackdropFilter(

        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

        child: Container(

          padding: const EdgeInsets.all(24.0),

          decoration: BoxDecoration(

            color: Colors.white.withValues(alpha: 0.95),

            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),

            border: Border.all(

              color: Colors.white.withValues(alpha: 0.8),

              width: 1.5,

            ),

          ),

          child: SingleChildScrollView(

            child: Column(

              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // Handle Bar

                Center(

                  child: Container(

                    width: 48,

                    height: 5,

                    decoration: BoxDecoration(

                      color: Colors.grey.shade300,

                      borderRadius: BorderRadius.circular(999),

                    ),

                  ),

                ),

                const SizedBox(height: 20),



                // Header Title

                Row(

                  children: [

                    Container(

                      width: 42,

                      height: 42,

                      decoration: BoxDecoration(

                        color: AppColors.primaryContainer,

                        borderRadius: BorderRadius.circular(14),

                      ),

                      child: const Icon(

                        Icons.spa_outlined,

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

                            'Bagaimana Suasana Hatimu?',

                            style: GoogleFonts.inter(

                              fontSize: 18,

                              fontWeight: FontWeight.w800,

                              color: AppColors.textPrimary,

                            ),

                          ),

                          Text(

                            'Pilih emosi & pemicu utama yang kamu rasakan.',

                            style: GoogleFonts.inter(

                              fontSize: 12,

                              color: AppColors.textSecondary,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 24),



                // 1. Select Mood Options

                Text(

                  'PILIH EMOSI',

                  style: GoogleFonts.inter(

                    fontSize: 11,

                    fontWeight: FontWeight.w700,

                    color: AppColors.textLight,

                    letterSpacing: 0.8,

                  ),

                ),

                const SizedBox(height: 12),

                SizedBox(

                  height: 90,

                  child: ListView.separated(

                    scrollDirection: Axis.horizontal,

                    itemCount: _moodOptions.length,

                    separatorBuilder: (context, index) => const SizedBox(width: 10),

                    itemBuilder: (context, index) {

                      final item = _moodOptions[index];

                      final isSelected = item['label'] == _selectedMoodLabel;

                      return GestureDetector(

                        onTap: () {

                          setState(() {

                            _selectedMoodLabel = item['label']!;

                            _selectedMoodEmoji = item['emoji']!;

                          });

                        },

                        child: AnimatedContainer(

                          duration: const Duration(milliseconds: 200),

                          width: 80,

                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),

                          decoration: BoxDecoration(

                            color: isSelected

                                ? AppColors.primaryContainer

                                : const Color(0xFFF4F6FF),

                            borderRadius: BorderRadius.circular(20),

                            border: Border.all(

                              color: isSelected

                                  ? AppColors.primary

                                  : Colors.transparent,

                              width: 2,

                            ),

                            boxShadow: isSelected

                                ? [

                                    BoxShadow(

                                      color: AppColors.primary.withValues(alpha: 0.15),

                                      blurRadius: 10,

                                      offset: const Offset(0, 4),

                                    ),

                                  ]

                                : null,

                          ),

                          child: Column(

                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [

                              Text(

                                item['emoji']!,

                                style: const TextStyle(fontSize: 26),

                              ),

                              const SizedBox(height: 6),

                              Text(

                                item['label']!.split(' ').first,

                                maxLines: 1,

                                overflow: TextOverflow.ellipsis,

                                style: GoogleFonts.inter(

                                  fontSize: 11,

                                  fontWeight: isSelected

                                      ? FontWeight.w700

                                      : FontWeight.w500,

                                  color: isSelected

                                      ? AppColors.primary

                                      : AppColors.textSecondary,

                                ),

                              ),

                            ],

                          ),

                        ),

                      );

                    },

                  ),

                ),

                const SizedBox(height: 24),



                // 2. Select Trigger Factors (No Checkmark Icon + Add Custom Button)

                Text(

                  'PEMICU UTAMA',

                  style: GoogleFonts.inter(

                    fontSize: 11,

                    fontWeight: FontWeight.w700,

                    color: AppColors.textLight,

                    letterSpacing: 0.8,

                  ),

                ),

                const SizedBox(height: 10),

                Wrap(

                  spacing: 8,

                  runSpacing: 8,

                  children: [

                    ..._triggerOptions.map((trigger) {

                      final isSelected = _selectedTriggers.contains(trigger);

                      return ChoiceChip(

                        showCheckmark: false,

                        label: Text(trigger),

                        selected: isSelected,

                        selectedColor: const Color(0xFFE2DAFF),

                        backgroundColor: const Color(0xFFF4F6FF),

                        labelStyle: GoogleFonts.inter(

                          fontSize: 12,

                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,

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

                            if (selected) {

                              _selectedTriggers.add(trigger);

                            } else {

                              _selectedTriggers.remove(trigger);

                            }

                          });

                        },

                      );

                    }),



                    // Add Custom Trigger Action Chip

                    ActionChip(

                      avatar: const Icon(Icons.add, size: 16, color: AppColors.primary),

                      label: Text(

                        'Tambah',

                        style: GoogleFonts.inter(

                          fontSize: 12,

                          fontWeight: FontWeight.w600,

                          color: AppColors.primary,

                        ),

                      ),

                      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.6),

                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(999),

                        side: const BorderSide(color: AppColors.primary, width: 1),

                      ),

                      onPressed: _showAddCustomTriggerDialog,

                    ),

                  ],

                ),

                const SizedBox(height: 24),



                // 3. Short Note TextField

                Text(

                  'CATATAN SINGKAT (OPSIONAL)',

                  style: GoogleFonts.inter(

                    fontSize: 11,

                    fontWeight: FontWeight.w700,

                    color: AppColors.textLight,

                    letterSpacing: 0.8,

                  ),

                ),

                const SizedBox(height: 10),

                Container(

                  decoration: BoxDecoration(

                    color: const Color(0xFFF4F6FF),

                    borderRadius: BorderRadius.circular(16),

                    border: Border.all(color: Colors.grey.shade300),

                  ),

                  child: TextField(

                    controller: _noteController,

                    maxLines: 2,

                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),

                    decoration: InputDecoration(

                      hintText: 'Ceritakan sedikit pemicu perasaanmu hari ini...',

                      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),

                      border: InputBorder.none,

                      contentPadding: const EdgeInsets.all(14),

                    ),

                  ),

                ),

                const SizedBox(height: 28),



                // 4. Save Button

                CustomPillButton(

                  text: 'Simpan Suasana Hati',

                  onPressed: () {

                    widget.onSave(_selectedMoodLabel, _selectedMoodEmoji);

                    Navigator.pop(context);

                  },

                ),

                const SizedBox(height: 16),

              ],

            ),

          ),

        ),

      ),

    );

  }

}

