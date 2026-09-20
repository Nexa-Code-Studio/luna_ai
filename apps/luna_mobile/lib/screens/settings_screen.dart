import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/skeleton_shimmer.dart';
import '../widgets/staggered_entrance.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Voice & AI Preferences
  String _selectedVoice = 'Luna - Lembut & Tenang';
  double _speechRate = 1.0;
  String _conversationMode = 'Hybrid (Deteksi Otomatis)';

  // Wellness Notifications & Reminders
  bool _dailyCheckInReminder = true;
  bool _eveningJournalReminder = true;
  bool _breathingExerciseReminder = false;

  // Privacy & Data Security
  bool _incognitoSessionMode = false;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedVoice = prefs.getString('settings_voice') ?? 'Luna - Lembut & Tenang';
        _speechRate = prefs.getDouble('settings_speech_rate') ?? 1.0;
        _conversationMode = prefs.getString('settings_conversation_mode') ?? 'Hybrid (Deteksi Otomatis)';
        _dailyCheckInReminder = prefs.getBool('settings_reminder_daily') ?? true;
        _eveningJournalReminder = prefs.getBool('settings_reminder_evening') ?? true;
        _breathingExerciseReminder = prefs.getBool('settings_reminder_breathing') ?? false;
        _incognitoSessionMode = prefs.getBool('settings_incognito') ?? false;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  void _showResetMemoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
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
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hapus Memori AI?',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus seluruh konteks percakapan emosional yang telah dipelajari LUNA? Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Memori percakapan AI berhasil dibersihkan.'),
                    backgroundColor: Color(0xFFD32F2F),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                'Ya, Hapus',
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
              // Header Bar with Clean Back Button
              StaggeredEntrance(
                index: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                          color: AppColors.textPrimary,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengaturan & Preferensi',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Sesuaikan pengalaman terapeutik Luna',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.5, color: AppColors.divider),

              // Scrollable Settings Content
              Expanded(
                child: _isLoading
                    ? const _SettingsProfileSkeletonLoader()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SECTION 1: PREFERENSI SUARA & AI
                            StaggeredEntrance(
                              index: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                    icon: Icons.record_voice_over_rounded,
                                    title: 'SUARA & RESPON LUNA AI',
                                  ),
                                  const SizedBox(height: 10),
                                  GlassCard(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Karakter Suara Selector Cards
                                        Text(
                                          'Karakter Suara Luna',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pilih kepribadian vokal yang paling membuatmu merasa aman dan didengar.',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildVoiceChoiceTile(
                                          title: 'Luna - Lembut & Tenang (Default)',
                                          subtitle: 'Suara hangat, empatik, dan menenangkan (id-ID-GadisNeural)',
                                          icon: Icons.spa_rounded,
                                          isSelected: _selectedVoice == 'Luna - Lembut & Tenang',
                                          onTap: () {
                                            setState(() => _selectedVoice = 'Luna - Lembut & Tenang');
                                            _saveSetting('settings_voice_character', 'Luna - Lembut & Tenang');
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        _buildVoiceChoiceTile(
                                          title: 'Aris - Bijak & Netral',
                                          subtitle: 'Suara maskulin yang suportif dan tegas (id-ID-ArdiNeural)',
                                          icon: Icons.self_improvement_rounded,
                                          isSelected: _selectedVoice == 'Aris - Bijak & Netral',
                                          onTap: () {
                                            setState(() => _selectedVoice = 'Aris - Bijak & Netral');
                                            _saveSetting('settings_voice_character', 'Aris - Bijak & Netral');
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        const Divider(height: 1, thickness: 0.5, color: AppColors.divider),
                                        const SizedBox(height: 14),

                                        // Kecepatan Bicara Slider
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Tempo Kecepatan Suara',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryContainer,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${_speechRate.toStringAsFixed(2)}x',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            activeTrackColor: AppColors.primary,
                                            inactiveTrackColor: AppColors.primaryContainer,
                                            thumbColor: AppColors.primary,
                                            overlayColor: AppColors.primary.withValues(alpha: 0.15),
                                            trackHeight: 4,
                                          ),
                                          child: Slider(
                                            value: _speechRate,
                                            min: 0.8,
                                            max: 1.2,
                                            divisions: 4,
                                            label: '${_speechRate.toStringAsFixed(2)}x',
                                            onChanged: (val) {
                                              setState(() => _speechRate = val);
                                              _saveSetting('settings_speech_rate', val);
                                            },
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Lambat (0.8x)', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
                                            Text('Normal (1.0x)', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
                                            Text('Cepat (1.2x)', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        const Divider(height: 1, thickness: 0.5, color: AppColors.divider),
                                        const SizedBox(height: 14),

                                        // Mode Percakapan Suara
                                        Text(
                                          'Metode Interaksi Suara',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildVoiceChoiceTile(
                                          title: 'Hybrid (Deteksi Suara Otomatis)',
                                          subtitle: 'Cukup berbicara langsung, Luna akan mendengarkan',
                                          icon: Icons.graphic_eq_rounded,
                                          isSelected: _conversationMode == 'Hybrid (Deteksi Otomatis)',
                                          onTap: () {
                                            setState(() => _conversationMode = 'Hybrid (Deteksi Otomatis)');
                                            _saveSetting('settings_conversation_mode', 'Hybrid (Deteksi Otomatis)');
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        _buildVoiceChoiceTile(
                                          title: 'Push-To-Talk (Manual)',
                                          subtitle: 'Tahan tombol untuk bicara, lepas untuk kirim suara',
                                          icon: Icons.touch_app_rounded,
                                          isSelected: _conversationMode == 'Push-To-Talk (Manual)',
                                          onTap: () {
                                            setState(() => _conversationMode = 'Push-To-Talk (Manual)');
                                            _saveSetting('settings_conversation_mode', 'Push-To-Talk (Manual)');
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // SECTION 2: PENGINGAT & KESEHATAN MENTAL
                            StaggeredEntrance(
                              index: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                    icon: Icons.notifications_active_rounded,
                                    title: 'PENGINGAT RUTINITAS WELLNESS',
                                  ),
                                  const SizedBox(height: 10),
                                  GlassCard(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _buildSwitchTile(
                                          icon: Icons.chat_bubble_outline_rounded,
                                          title: 'Pengingat Sesi Curhat Pagi',
                                          subtitle: 'Notifikasi ramah untuk menyapa emosimu saat memulai hari',
                                          value: _dailyCheckInReminder,
                                          onChanged: (val) {
                                            setState(() => _dailyCheckInReminder = val);
                                            _saveSetting('settings_reminder_daily', val);
                                          },
                                        ),
                                        const Divider(height: 20, thickness: 0.5, color: AppColors.divider),
                                        _buildSwitchTile(
                                          icon: Icons.menu_book_rounded,
                                          title: 'Refleksi Jurnal Malam',
                                          subtitle: 'Pengingat membaca sintesis emosi harian pukul 20:00 WIB',
                                          value: _eveningJournalReminder,
                                          onChanged: (val) {
                                            setState(() => _eveningJournalReminder = val);
                                            _saveSetting('settings_reminder_evening', val);
                                          },
                                        ),
                                        const Divider(height: 20, thickness: 0.5, color: AppColors.divider),
                                        _buildSwitchTile(
                                          icon: Icons.air_rounded,
                                          title: 'Latihan Napas & Relaksasi',
                                          subtitle: 'Ajakan latihan pernapasan 4-7-8 untuk menstabilkan detak jantung',
                                          value: _breathingExerciseReminder,
                                          onChanged: (val) {
                                            setState(() => _breathingExerciseReminder = val);
                                            _saveSetting('settings_reminder_breathing', val);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // SECTION 3: PRIVASI & KEAMANAN DATA
                            StaggeredEntrance(
                              index: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                    icon: Icons.shield_outlined,
                                    title: 'PRIVASI & KEAMANAN DATA',
                                  ),
                                  const SizedBox(height: 10),
                                  GlassCard(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _buildSwitchTile(
                                          icon: Icons.visibility_off_outlined,
                                          title: 'Mode Sesi Privat (Incognito)',
                                          subtitle: 'Sesi dialog tidak dicatat ke memori jangka panjang AI',
                                          value: _incognitoSessionMode,
                                          onChanged: (val) {
                                            setState(() => _incognitoSessionMode = val);
                                            _saveSetting('settings_incognito', val);
                                          },
                                        ),
                                        const Divider(height: 20, thickness: 0.5, color: AppColors.divider),
                                        _buildActionTile(
                                          icon: Icons.delete_outline_rounded,
                                          iconColor: const Color(0xFFD32F2F),
                                          title: 'Hapus Memori AI Luna',
                                          subtitle: 'Bersihkan seluruh riwayat konteks emosional yang tersimpan',
                                          onTap: _showResetMemoryDialog,
                                        ),
                                        const Divider(height: 20, thickness: 0.5, color: AppColors.divider),
                                        _buildActionTile(
                                          icon: Icons.contact_phone_outlined,
                                          iconColor: AppColors.primary,
                                          title: 'Kontak Darurat & Protokol Krisis',
                                          subtitle: 'Kelola kontak darurat terpercaya dan hotline resmi 24 jam',
                                          onTap: () => Navigator.pushNamed(context, '/emergency_contacts'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // SECTION 4: TENTANG APLIKASI
                            StaggeredEntrance(
                              index: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                    icon: Icons.info_outline_rounded,
                                    title: 'TENTANG APLIKASI',
                                  ),
                                  const SizedBox(height: 10),
                                  GlassCard(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        _buildActionTile(
                                          icon: Icons.description_outlined,
                                          iconColor: AppColors.primary,
                                          title: 'Syarat, Ketentuan & Disclaimer Medis',
                                          subtitle: 'Pelajari batasan klinis dan privasi data pengguna',
                                          onTap: () => Navigator.pushNamed(context, '/terms_disclaimer'),
                                        ),
                                        const Divider(height: 20, thickness: 0.5, color: AppColors.divider),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryContainer,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(Icons.verified_outlined, size: 18, color: AppColors.primary),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Versi Aplikasi',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              'LUNA AI v1.0.4 • Build 2026.09 (Production)',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                         child: Text(
                                           'Terbaru',
                                           style: GoogleFonts.inter(
                                             fontSize: 10,
                                             fontWeight: FontWeight.w700,
                                             color: const Color(0xFF047857),
                                           ),
                                         ),
                                       ),
                                     ],
                                   ),
                                 ],
                               ),
                             ),
                           ],
                         ),
                       ),
                       const SizedBox(height: 40),
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

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceChoiceTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0FDF4) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isSelected ? const Color(0xFF047857) : AppColors.textLight,
                ),
              ),
              const SizedBox(width: 10),
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
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                size: 20,
                color: isSelected ? const Color(0xFF10B981) : AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
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
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: const Color(0xFF10B981),
          activeTrackColor: const Color(0xFFD1FAE5),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
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
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton loader for Settings screen.
class _SettingsProfileSkeletonLoader extends StatelessWidget {
  const _SettingsProfileSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmerHost(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Voice & AI Preferences
            Row(
              children: const [
                SkeletonCircle(size: 20),
                SizedBox(width: 8),
                SkeletonLine(width: 140, height: 13),
              ],
            ),
            const SizedBox(height: 10),
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLine(width: 120, height: 14),
                  SizedBox(height: 12),
                  SkeletonBox(width: double.infinity, height: 44, borderRadius: 10),
                  SizedBox(height: 16),
                  SkeletonLine(width: 100, height: 14),
                  SizedBox(height: 12),
                  SkeletonBox(width: double.infinity, height: 28, borderRadius: 10),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Notifications & Reminders
            Row(
              children: const [
                SkeletonCircle(size: 20),
                SizedBox(width: 8),
                SkeletonLine(width: 170, height: 13),
              ],
            ),
            const SizedBox(height: 10),
            GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: index == 2 ? 0 : 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              SkeletonLine(width: 140, height: 14),
                              SizedBox(height: 6),
                              SkeletonLine(width: 190, height: 11),
                            ],
                          ),
                        ),
                        const SkeletonBox(width: 44, height: 24, borderRadius: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
