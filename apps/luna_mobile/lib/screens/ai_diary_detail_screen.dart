import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/staggered_entrance.dart';

Color _parseColor(dynamic colorVal, Color fallback) {
  if (colorVal is Color) return colorVal;
  if (colorVal is String && colorVal.startsWith('#')) {
    final hex = colorVal.replaceAll('#', '');
    if (hex.length == 6) {
      try {
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
  }
  return fallback;
}

class AiDiaryDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? journalData;

  const AiDiaryDetailScreen({super.key, this.journalData});

  @override
  State<AiDiaryDetailScreen> createState() => _AiDiaryDetailScreenState();
}

class _AiDiaryDetailScreenState extends State<AiDiaryDetailScreen> {
  late String _selectedSessionId;
  bool _isInitialized = false;
  Map<String, dynamic>? _diaryData;
  bool _isTranscriptExpanded = false;

  // Streaming and Skeleton State
  bool _isStreaming = false;
  bool _isLoadingSkeleton = false;
  bool _streamError = false;
  String? _streamedSummary;
  http.Client? _streamClient;

  @override
  void dispose() {
    _streamClient?.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = widget.journalData ??
          (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?);
      if (args != null) {
        _diaryData = Map<String, dynamic>.from(args);
        if (args['selectedSessionId'] != null) {
          _selectedSessionId = args['selectedSessionId'].toString();
        } else {
          _selectedSessionId = 'all';
        }

        final bool isSingle = _diaryData!['isSingleSession'] == true;
        final dId = _diaryData!['id'];

        if (isSingle) {
          final convId = _diaryData!['conversationId'] ?? dId;
          final existingSummary = _diaryData!['summary'];
          if (existingSummary == null || existingSummary.toString().trim().isEmpty) {
            if (convId != null) {
              _streamSummary(convId.toString());
            }
          } else {
            _streamedSummary = existingSummary.toString();
          }
        } else if (dId != null) {
          _fetchDiaryDetail(dId.toString());
        }
      } else {
        _selectedSessionId = 'all';
      }
      _isInitialized = true;
    }
  }

  Future<void> _streamSummary(String conversationId) async {
    if (AppConfig.useMockData) {
      setState(() {
        _isLoadingSkeleton = true;
        _isStreaming = true;
        _streamError = false;
        _streamedSummary = null;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _isLoadingSkeleton = false;
        _streamedSummary =
            'Sesi percakapan curhat bersama LUNA berjalan dengan hangat dan memberikan ruang aman untuk refleksi batin.';
        _isStreaming = false;
      });
      return;
    }

    if (_isStreaming) return;

    setState(() {
      _isLoadingSkeleton = true;
      _isStreaming = true;
      _streamError = false;
      _streamedSummary = null;
    });

    try {
      final headers = await AppConfig.getAuthHeaders();
      final url = Uri.parse('${AppConfig.baseUrl}/conversations/$conversationId/summary/stream');
      final request = http.Request('GET', url);
      request.headers.addAll(headers);

      _streamClient?.close();
      _streamClient = http.Client();
      final streamedResponse =
          await _streamClient!.send(request).timeout(const Duration(seconds: 25));

      if (streamedResponse.statusCode != 200) {
        throw Exception('Stream endpoint returned status ${streamedResponse.statusCode}');
      }

      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (!mounted) break;
        final trimmed = line.trim();
        if (trimmed.startsWith('data:')) {
          final jsonStr = trimmed.substring(5).trim();
          if (jsonStr.isEmpty) continue;
          try {
            final Map<String, dynamic> payload = jsonDecode(jsonStr);
            if (payload.containsKey('token')) {
              final token = payload['token']?.toString() ?? '';
              if (mounted) {
                setState(() {
                  _isLoadingSkeleton = false;
                  _streamedSummary = (_streamedSummary ?? '') + token;
                });
              }
            }
            if (payload['done'] == true) {
              final finalSummary = payload['summary']?.toString();
              final newEmotion = payload['dominant_emotion']?.toString();
              final newEmoji = payload['dominant_emoji']?.toString();
              if (mounted) {
                setState(() {
                  _isStreaming = false;
                  _isLoadingSkeleton = false;
                  if (finalSummary != null && finalSummary.isNotEmpty) {
                    _streamedSummary = finalSummary;
                  }
                  if (_diaryData != null) {
                    _diaryData!['summary'] = _streamedSummary;
                    if (newEmotion != null && newEmotion.isNotEmpty) {
                      _diaryData!['moodTag'] = newEmotion;
                    }
                    if (newEmoji != null && newEmoji.isNotEmpty) {
                      _diaryData!['moodEmoji'] = newEmoji;
                    }
                  }
                });
              }
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStreaming = false;
          _isLoadingSkeleton = false;
          _streamError = true;
        });
      }
    } finally {
      if (mounted && _isStreaming) {
        setState(() {
          _isStreaming = false;
          _isLoadingSkeleton = false;
        });
      }
      _streamClient?.close();
      _streamClient = null;
    }
  }

  Future<void> _fetchDiaryDetail(String diaryId) async {
    if (AppConfig.useMockData) return;
    try {
      final headers = await AppConfig.getAuthHeaders();
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrl}/diaries/$diaryId'), headers: headers)
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _diaryData = data;
          });
        }
      }
    } catch (_) {
      // Keep existing data
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default fallback data if passed data is null
    final args = widget.journalData ??
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?);

    final data = _diaryData ?? args ?? {

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



    final bool isSingleSession = data['isSingleSession'] == true;
    final bool hasRisk = data['riskWarning'] != null && data['riskWarning']['detected'] == true;

    final List<dynamic> rawEvents = data['importantEvents'] is List ? data['importantEvents'] as List : [];
    final List<String> importantEvents = rawEvents.isNotEmpty
        ? rawEvents.map((e) => e.toString()).toList()
        : ['Sesi refleksi harian tercatat dalam sistem LUNA.'];

    final List<Map<String, dynamic>> sessions = (data['sessions'] is List && (data['sessions'] as List).isNotEmpty)
        ? (data['sessions'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : [];

    // Ensure _selectedSessionId is valid
    if (_selectedSessionId != 'all' && sessions.isNotEmpty) {
      final exists = sessions.any((s) => s['id'].toString() == _selectedSessionId);
      if (!exists) {
        _selectedSessionId = 'all';
      }
    }

    // Compute active 7-emotion breakdown list based on selected session
    List<Map<String, dynamic>> activeEmotions = [];
    if (_selectedSessionId == 'all') {
      if (data['emotionsBreakdown'] is List && (data['emotionsBreakdown'] as List).isNotEmpty) {
        activeEmotions = (data['emotionsBreakdown'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        activeEmotions = [
          {'name': 'fear', 'label': 'Takut / Gelisah', 'emoji': '😨', 'percent': 0.45, 'color': const Color(0xFF6C63FF)},
          {'name': 'sadness', 'label': 'Sedih / Haru', 'emoji': '😔', 'percent': 0.25, 'color': const Color(0xFF8B93FF)},
          {'name': 'netral', 'label': 'Netral', 'emoji': '😐', 'percent': 0.15, 'color': const Color(0xFFA7E6FF)},
          {'name': 'happy', 'label': 'Bahagia', 'emoji': '😃', 'percent': 0.10, 'color': const Color(0xFFFFE6A7)},
          {'name': 'surprise', 'label': 'Terkejut', 'emoji': '😲', 'percent': 0.03, 'color': const Color(0xFFC3B8FF)},
          {'name': 'anger', 'label': 'Marah', 'emoji': '😡', 'percent': 0.01, 'color': const Color(0xFFFFB6C1)},
          {'name': 'disgusted', 'label': 'Jijik / Muak', 'emoji': '🤢', 'percent': 0.01, 'color': const Color(0xFFB8C2FC)},
        ];
      }
    } else {
      Map<String, dynamic>? selectedSessData;
      for (var s in sessions) {
        if (s['id'].toString() == _selectedSessionId) {
          selectedSessData = s;
          break;
        }
      }
      if (selectedSessData == null && sessions.isNotEmpty) {
        selectedSessData = sessions.first;
      }

      if (selectedSessData != null &&
          selectedSessData['emotionsBreakdown'] is List &&
          (selectedSessData['emotionsBreakdown'] as List).isNotEmpty) {
        activeEmotions = (selectedSessData['emotionsBreakdown'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        activeEmotions = [
          {'name': 'netral', 'label': 'Ketenangan & Refleksi', 'emoji': '😌', 'percent': 0.60, 'color': const Color(0xFFA7E6FF)},
          {'name': 'happy', 'label': 'Lega & Nyaman', 'emoji': '😃', 'percent': 0.40, 'color': const Color(0xFFFFE6A7)},
        ];
      }
    }

    // Compute active transcripts list based on selected session
    List<Map<String, dynamic>> activeTranscripts = [];
    if (_selectedSessionId == 'all') {
      for (var s in sessions) {
        final rawTrans = s['transcripts'];
        if (rawTrans is List) {
          for (var t in rawTrans) {
            if (t is Map) {
              activeTranscripts.add({
                ...Map<String, dynamic>.from(t),
                'sessionTitle': s['title'] ?? 'Sesi',
              });
            }
          }
        }
      }
    } else {
      Map<String, dynamic>? selectedSessData;
      for (var s in sessions) {
        if (s['id'].toString() == _selectedSessionId) {
          selectedSessData = s;
          break;
        }
      }
      if (selectedSessData == null && sessions.isNotEmpty) {
        selectedSessData = sessions.first;
      }
      if (selectedSessData != null) {
        final rawTrans = selectedSessData['transcripts'];
        if (rawTrans is List) {
          for (var t in rawTrans) {
            if (t is Map) {
              activeTranscripts.add({
                ...Map<String, dynamic>.from(t),
                'sessionTitle': selectedSessData['title'] ?? 'Sesi',
              });
            }
          }
        }
      }
    }

    const int initialTranscriptLimit = 6;
    final bool canExpand = activeTranscripts.length > initialTranscriptLimit;
    final int displayCount = (_isTranscriptExpanded || !canExpand)
        ? activeTranscripts.length
        : initialTranscriptLimit;

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
              StaggeredEntrance(
                index: 0,
                child: Padding(
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
                            data['title']?.toString() ?? 'Refleksi Harian LUNA',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${data['date'] ?? 'Hari ini'} • ${data['moodTag'] ?? 'Tenang & Nyaman'}',
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
                  ],
                ),
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
                        StaggeredEntrance(
                          index: 1,
                          child: Container(

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
                                          data['riskWarning']?['title']?.toString() ?? 'Peringatan Kesehatan Mental',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFD32F2F),
                                          ),
                                        ),
                                        Text(
                                          'Tingkat: ${data['riskWarning']?['level']?.toString() ?? 'Sedang'}',
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
                                data['riskWarning']?['message']?.toString() ?? 'Perhatikan kondisi emosionalmu hari ini.',
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
                      ),
                      const SizedBox(height: 20),
                    ],



                      // 1. WAWASAN AI KUMULATIF
                      StaggeredEntrance(
                        index: 2,
                        child: GlassCard(

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
                                        isSingleSession ? 'RINGKASAN PERCAKAPAN' : 'WAWASAN AI KUMULATIF',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      Text(
                                        isSingleSession
                                            ? '✨ Ringkasan cerdas percakapan sesi suara bersama LUNA'
                                            : '✨ Diperbarui setelah Sesi #${sessions.length} (${data['lastSessionTime'] ?? 'Hari ini'})',
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
                            if (isSingleSession && _isLoadingSkeleton)
                              const _SummarySkeletonLoader()
                            else if (isSingleSession && _isStreaming)
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                                  children: [
                                    TextSpan(text: _streamedSummary ?? ''),
                                    const TextSpan(
                                      text: ' ▋',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (isSingleSession &&
                                _streamError &&
                                (_streamedSummary == null || _streamedSummary!.isEmpty))
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ringkasan percakapan belum berhasil dimuat.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textLight,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: () {
                                      final convId = data['conversationId'] ?? data['id'];
                                      if (convId != null) {
                                        _streamSummary(convId.toString());
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.auto_awesome,
                                              size: 14,
                                              color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            '✨ Generate Ringkasan',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                (isSingleSession
                                        ? (_streamedSummary ??
                                            data['summary'] ??
                                            data['aiInsight'])
                                        : data['aiInsight'])
                                    ?.toString() ??
                                    'Analisis AI menunjukkan kondisi emosional kamu hari ini cukup stabil.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),

                          ],
                        ),
                      ),
                      ),
                      const SizedBox(height: 16),



                      if (!isSingleSession) ...[
                        StaggeredEntrance(
                          index: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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

                              ...importantEvents.map(

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
                                data['emotionalReflection']?.toString() ??
                                    'Merasa lebih tenang dan terarah setelah berefleksi bersama LUNA.',
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
                            ],
                          ),
                        ),
                       ],

                      StaggeredEntrance(
                        index: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SESSION SELECTOR CHIPS SECTION
                            if (!isSingleSession && sessions.isNotEmpty) ...[
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
                                onSelected: (_) => setState(() {
                                  _selectedSessionId = 'all';
                                  _isTranscriptExpanded = false;
                                }),
                              ),
                              const SizedBox(width: 8),
                              ...sessions.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final sess = entry.value;
                                final isSel = sess['id'].toString() == _selectedSessionId;
                                final rawTime = sess['time']?.toString().trim();
                                final timeStr = (rawTime != null && rawTime != '-' && rawTime.isNotEmpty)
                                    ? rawTime
                                    : 'Sesi #${idx + 1}';
                                final emoji = (sess['moodEmoji'] != null && sess['moodEmoji'].toString().isNotEmpty)
                                    ? sess['moodEmoji'].toString()
                                    : '🎙️';
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    showCheckmark: false,
                                    label: Text('$emoji $timeStr'),
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
                                    onSelected: (_) => setState(() {
                                      _selectedSessionId = sess['id'].toString();
                                      _isTranscriptExpanded = false;
                                    }),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

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
                              isSingleSession
                                  ? 'SESI INI'
                                  : (_selectedSessionId == 'all' ? 'KUMULATIF' : 'SESI SPESIFIK'),
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
                            final double pct = ((emo['percent'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
                            final int pctInt = (pct * 100).round();
                            final Color emoColor = _parseColor(emo['color'], AppColors.primary);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(emo['emoji']?.toString() ?? '✨', style: const TextStyle(fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Text(
                                            emo['label']?.toString() ?? 'Emosi',
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
                                      valueColor: AlwaysStoppedAnimation<Color>(emoColor),
                                    ),
                                  ),

                                ],

                              ),

                            );

                          }).toList(),
                        ),
                      ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),



                      // 5. TRANSKRIP PERCAKAPAN SUARA (Voice-to-Text Filtered with overflow protection)
                      StaggeredEntrance(
                        index: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            canExpand && !_isTranscriptExpanded
                                ? 'Menampilkan $displayCount dari ${activeTranscripts.length}'
                                : '${activeTranscripts.length} Percakapan',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (activeTranscripts.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.forum_outlined, size: 36, color: Color(0xFFB0B7C3)),
                              const SizedBox(height: 8),
                              Text(
                                'Tidak ada transkrip rekaman suara tersimpan untuk sesi ini',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayCount,
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
                                  Column(
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
                                          if (isUser && item['emotionTag'] != null)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(item['emotionEmoji'] ?? '', style: const TextStyle(fontSize: 12)),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEADBFF),
                                                    borderRadius: BorderRadius.circular(999),
                                                  ),
                                                  child: Text(
                                                    item['emotionTag']?.toString() ?? '',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      if (_selectedSessionId == 'all' && sessions.length > 1 && item['sessionTitle'] != null) ...[
                                        const SizedBox(height: 5),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.grey.shade300, width: 0.8),
                                          ),
                                          child: Text(
                                            '🎙️ ${item['sessionTitle']}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['text']?.toString() ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (item['time'] != null && item['time'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        item['time']?.toString() ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                        if (canExpand) ...[
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isTranscriptExpanded = !_isTranscriptExpanded;
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isTranscriptExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isTranscriptExpanded
                                        ? 'Tampilkan Lebih Sedikit'
                                        : 'Lihat Selengkapnya (${activeTranscripts.length - initialTranscriptLimit} pesan lainnya)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                          ],
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

}

class _SummarySkeletonLoader extends StatefulWidget {
  const _SummarySkeletonLoader();

  @override
  State<_SummarySkeletonLoader> createState() => _SummarySkeletonLoaderState();
}

class _SummarySkeletonLoaderState extends State<_SummarySkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: opacity * 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: MediaQuery.of(context).size.width * 0.78,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: opacity * 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: MediaQuery.of(context).size.width * 0.52,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: opacity * 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        );
      },
    );
  }
}

