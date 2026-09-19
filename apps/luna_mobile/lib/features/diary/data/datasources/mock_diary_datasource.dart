import 'diary_datasource.dart';
import '../models/diary_entry_model.dart';
import '../models/risk_warning_model.dart';

class MockDiaryDataSource implements DiaryDataSource {
  final List<DiaryEntryModel> _entries = [
    const DiaryEntryModel(
      id: 'diary_samsul_today_00',
      title: 'Jurnal Refleksi Hari Ini',
      date: '1 September 2026',
      sessionCount: 1,
      lastSessionTime: '08:15 AM',
      moodTag: 'Bahagia 😃',
      moodEmoji: '😃',
      summary: 'Samsul merasa lebih semangat dan positif setelah berdiskusi mengenai target pribadi dan meditasi pagi bersama LUNA.',
      aiInsight: 'Progres emosional Samsul menunjukkan peningkatan kebahagiaan dan motivasi positif.',
      importantEvents: [
        '[Sesi #1] Afirmasi positif pagi dan perencanaan aktivitas produktif.',
      ],
      emotionalReflection: 'Merasa optimis menghadapi tantangan hari ini.',
      sessions: [
        DiarySessionSummaryModel(
          id: 'sess_samsul_0',
          title: 'Afirmasi Pagi',
          time: '08:15 AM',
          moodTag: 'Bahagia 😃',
          moodEmoji: '😃',
        ),
      ],
    ),
    const DiaryEntryModel(
      id: 'diary_samsul_normal_02',
      title: 'Catatan Refleksi Emosi Harian',
      date: '31 Agustus 2026',
      sessionCount: 1,
      lastSessionTime: '20:15 PM',
      moodTag: 'Tenang 😌',
      moodEmoji: '😌',
      summary: 'Samsul merasakan ketenangan setelah menyelesaikan sesi konsultasi mengenai manajemen waktu dan relaksasi pikiran.',
      aiInsight: 'Kondisi emosional Samsul tergolong stabil dan mengalami pemulihan energi emosional yang baik.',
      importantEvents: [
        '[Sesi #1] Refleksi mengenai rutinitas harian dan teknik olah napas.',
      ],
      emotionalReflection: 'Merasa lebih lega dan siap melanjutkan aktivitas esok hari.',
      sessions: [
        DiarySessionSummaryModel(
          id: 'sess_samsul_3',
          title: 'Refleksi Rutinitas Malam',
          time: '20:15 PM',
          moodTag: 'Tenang 😌',
          moodEmoji: '😌',
        ),
      ],
    ),
    const DiaryEntryModel(
      id: 'diary_samsul_anxiety_03',
      title: 'Diskusi Beban Kerja & Stres',
      date: '30 Agustus 2026',
      sessionCount: 1,
      lastSessionTime: '19:40 PM',
      moodTag: 'Cemas 😰',
      moodEmoji: '😰',
      summary: 'Samsul mengutarakan rasa khawatir terkait tenggat waktu pekerjaan dan mencoba menerapkan latihan olah napas 4-7-8.',
      aiInsight: 'Terdeteksi peningkatan kecemasan sedang. LUNA merekomendasikan jeda istirahat singkat.',
      importantEvents: [
        '[Sesi #1] Diskusi penanganan kecemasan akademis/pekerjaan.',
      ],
      emotionalReflection: 'Mulai memahami pemicu kecemasan dan mengelola fokus secara bertahap.',
      sessions: [
        DiarySessionSummaryModel(
          id: 'sess_samsul_4',
          title: 'Konsultasi Manajemen Kecemasan',
          time: '19:40 PM',
          moodTag: 'Cemas 😰',
          moodEmoji: '😰',
        ),
      ],
    ),
    const DiaryEntryModel(
      id: 'diary_samsul_emergency_01',
      title: 'Jurnal Emosional Krisis — Samsul',
      date: '28 Agustus 2026',
      sessionCount: 2,
      lastSessionTime: '07:30 AM',
      moodTag: 'Darurat 🚨',
      moodEmoji: '🚨',
      summary: 'Samsul mengutarakan rasa kecemasan dan kelelahan mental ekstrem terkait beban kerja dan kondisi krisis. Terdeteksi indikasi krisis emosional tinggi.',
      riskWarning: RiskWarningModel(
        detected: true,
        type: 'High Risk / Krisis',
        title: 'PERINGATAN KRISIS EMOSIONAL',
        level: 'RISIKO TINGGI',
        message: 'Sistem LUNA mendeteksi indikasi krisis emosional tinggi dan stres berat pada percakapan Samsul hari ini. Protokol keselamatan aktif untuk rujukan darurat.',
      ),
      aiInsight: 'Luna AI mengaktifkan mode de-eskalasi dan menyajikan rujukan kontak krisis darurat (Hotline 119 ext 8).',
      importantEvents: [
        '[Sesi #1] Samsul menyampaikan keluhan kelelahan fisik dan kecemasan mendalam.',
        '[Sesi #2] Terdeteksi puncak stres emosional tinggi — Protokol Krisis dipicu.',
      ],
      emotionalReflection: 'Samsul menganjurkan diri untuk beristirahat penuh dan menghubungi Kontak Darurat Utama atau Konselor Profesional.',
      sessions: [
        DiarySessionSummaryModel(
          id: 'sess_samsul_1',
          title: 'Refleksi Stres Pagi',
          time: '07:15 AM',
          moodTag: 'Stres 💥',
          moodEmoji: '😰',
        ),
        DiarySessionSummaryModel(
          id: 'sess_samsul_2',
          title: 'Panggilan Suara Krisis',
          time: '07:30 AM',
          moodTag: 'Darurat 🚨',
          moodEmoji: '🚨',
        ),
      ],
    ),
  ];

  @override
  Future<List<DiaryEntryModel>> getDiaryEntries({String? moodFilter, String? searchQuery}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var results = List<DiaryEntryModel>.from(_entries);

    if (moodFilter != null && moodFilter != 'Semua') {
      final cleanFilter = moodFilter.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
      results = results.where((e) => e.moodTag.toLowerCase().contains(cleanFilter)).toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      results = results.where((e) =>
        e.title.toLowerCase().contains(q) ||
        e.summary.toLowerCase().contains(q)
      ).toList();
    }

    return results;
  }

  @override
  Future<DiaryEntryModel?> getDiaryEntryById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return _entries.isNotEmpty ? _entries.first : null;
    }
  }

  @override
  Future<DiaryEntryModel?> getTodayDiary() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _entries.isNotEmpty ? _entries.first : null;
  }

  @override
  Future<DiaryEntryModel?> generateTodayDiary() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _entries.isNotEmpty ? _entries.first : null;
  }

  @override
  Future<DiaryEntryModel> createDiaryEntry(String content, String moodTag) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newEntry = DiaryEntryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Jurnal ${DateTime.now().day}/${DateTime.now().month}',
      date: '${DateTime.now().day} Oktober ${DateTime.now().year}',
      sessionCount: 1,
      lastSessionTime: '${DateTime.now().hour}:${DateTime.now().minute}',
      moodTag: moodTag,
      moodEmoji: '📝',
      summary: content,
      aiInsight: 'Analisis AI sedang diproses untuk jurnal baru ini.',
      importantEvents: ['[Sesi #1] Catatan mandiri'],
      emotionalReflection: 'Refleksi awal setelah menulis jurnal.',
      sessions: const [],
    );
    _entries.insert(0, newEntry);
    return newEntry;
  }

  @override
  Future<void> deleteDiaryEntry(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _entries.removeWhere((e) => e.id == id);
  }
}
