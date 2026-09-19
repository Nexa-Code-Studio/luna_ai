import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/glass_card.dart';
import '../providers/dass_provider.dart';
import '../../domain/entities/dass_assessment_entity.dart';

class DASSFormCard extends ConsumerStatefulWidget {
  const DASSFormCard({super.key});

  @override
  ConsumerState<DASSFormCard> createState() => _DASSFormCardState();
}

class _DASSFormCardState extends ConsumerState<DASSFormCard> {
  bool _isExpanded = false;

  Color _getScaleColor(String scale) {
    switch (scale.toLowerCase()) {
      case 'depression':
        return const Color(0xFF74B9FF);
      case 'anxiety':
        return const Color(0xFF6C63FF);
      case 'stress':
      default:
        return const Color(0xFFFF7675);
    }
  }

  String _getScaleLabel(String scale) {
    switch (scale.toLowerCase()) {
      case 'depression':
        return 'Depresi';
      case 'anxiety':
        return 'Kecemasan';
      case 'stress':
      default:
        return 'Stres';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dassState = ref.watch(dassAssessmentNotifierProvider);
    final notifier = ref.read(dassAssessmentNotifierProvider.notifier);

    return dassState.assessment.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, _) => GlassCard(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 8),
            Text(
              'Gagal memuat asesmen DASS-21: $err',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => notifier.loadTodayAssessment(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
      data: (assessment) {
        final isVerified = assessment.verifiedByUser;
        final staged = dassState.stagedScores;
        final bool hasChanges =
            assessment.items.any((it) => (staged[it.itemId] ?? it.score) != it.score);

        return GlassCard(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology_outlined,
                      color: Color(0xFF1A73E8),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Asesmen DASS-21',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1B4B),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isVerified ? const Color(0xFFE6F4EA) : const Color(0xFFFFF0D4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isVerified ? 'Diverifikasi User' : 'Estimasi AI',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isVerified ? const Color(0xFF137333) : const Color(0xFFB06000),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Deteksi otomatis dari obrolan santai & koreksi mandiri.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Subscale Scores Badges
              Row(
                children: [
                  _buildSubscalePill('Stres', assessment.stressScore, assessment.stressSeverity, const Color(0xFFFF7675)),
                  const SizedBox(width: 8),
                  _buildSubscalePill('Kecemasan', assessment.anxietyScore, assessment.anxietySeverity, const Color(0xFF6C63FF)),
                  const SizedBox(width: 8),
                  _buildSubscalePill('Depresi', assessment.depressionScore, assessment.depressionSeverity, const Color(0xFF74B9FF)),
                ],
              ),
              const SizedBox(height: 16),

              // Expand / Collapse Action
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded ? 'Tutup Daftar 21 Butir Soal' : 'Lihat & Edit 21 Butir Soal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 20,
                        color: const Color(0xFF374151),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded 21 Items Form
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assessment.items.length,
                  separatorBuilder: (context, index) => const Divider(height: 24, color: Color(0xFFE5E7EB)),
                  itemBuilder: (context, index) {
                    final item = assessment.items[index];
                    final currentScore = staged[item.itemId] ?? item.score;
                    return _buildQuestionItem(item, currentScore, notifier);
                  },
                ),
                // Animated Slide-Up Save Button (only visible when changes exist)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: hasChanges
                      ? Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: AnimatedSlide(
                            offset: hasChanges ? Offset.zero : const Offset(0, 0.5),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: dassState.isSaving
                                    ? null
                                    : () async {
                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                        final success = await notifier.saveAssessment();
                                        if (!mounted) return;
                                        if (success) {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Koreksi DASS-21 berhasil disimpan & ritem emosional diselaraskan!',
                                                style: GoogleFonts.plusJakartaSans(),
                                              ),
                                              backgroundColor: const Color(0xFF10B981),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: dassState.isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                        'Simpan Koreksi',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubscalePill(String title, int score, String severity, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$score',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1B4B),
              ),
            ),
            Text(
              severity,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem(DASSItemEntity item, int currentScore, DASSAssessmentNotifier notifier) {
    final scaleColor = _getScaleColor(item.scale);
    final scaleLabel = _getScaleLabel(item.scale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: scaleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Item ${item.itemId} • $scaleLabel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scaleColor,
                ),
              ),
            ),
            if (item.isUserEdited) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Telah Diedit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4338CA),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          item.questionText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F2937),
            height: 1.3,
          ),
        ),

        // Bukti kutipan dari percakapan AI jika ada
        if (item.evidence != null && item.evidence!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote_rounded, size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.evidence!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),

        // Pilihan Likert 0-3
        Row(
          children: [
            _buildLikertOption(0, '0: Tdk Pernah', currentScore == 0, () => notifier.updateScore(item.itemId, 0)),
            const SizedBox(width: 6),
            _buildLikertOption(1, '1: Kadang', currentScore == 1, () => notifier.updateScore(item.itemId, 1)),
            const SizedBox(width: 6),
            _buildLikertOption(2, '2: Sering', currentScore == 2, () => notifier.updateScore(item.itemId, 2)),
            const SizedBox(width: 6),
            _buildLikertOption(3, '3: Selalu', currentScore == 3, () => notifier.updateScore(item.itemId, 3)),
          ],
        ),
      ],
    );
  }

  Widget _buildLikertOption(int score, String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFD1D5DB),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
