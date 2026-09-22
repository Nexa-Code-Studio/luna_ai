import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/skeleton_shimmer.dart';
import '../widgets/staggered_entrance.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ($text) berhasil disalin ke clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final headers = await AppConfig.getAuthHeaders();
      final res = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/users/emergency-contacts'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _contacts = data.map<Map<String, dynamic>>((c) => {
              'id': c['id']?.toString() ?? '',
              'name': c['name']?.toString() ?? '',
              'relation': (c['relationship'] ?? c['relation'])?.toString() ?? 'Kontak Darurat',
              'phone': (c['phone'] ?? c['phone_number'])?.toString() ?? '',
              'isPrimary': c['isPrimary'] == true || c['is_primary'] == true,
            }).toList();
          });
        }
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveContactToBackend({
    required String name,
    required String relation,
    required String phone,
    required bool isPrimary,
    Map<String, dynamic>? contactToEdit,
  }) async {
    setState(() {
      if (isPrimary) {
        for (var c in _contacts) {
          c['isPrimary'] = false;
        }
      }
      if (contactToEdit != null) {
        contactToEdit['name'] = name;
        contactToEdit['relation'] = relation;
        contactToEdit['phone'] = phone;
        contactToEdit['isPrimary'] = isPrimary;
      } else {
        _contacts.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': name,
          'relation': relation.isEmpty ? 'Kontak Darurat' : relation,
          'phone': phone,
          'isPrimary': isPrimary || _contacts.isEmpty,
        });
      }
    });

    try {
      final headers = await AppConfig.getAuthHeaders();
      if (contactToEdit != null) {
        // UPDATE existing contact via PUT
        final contactId = contactToEdit['id']?.toString() ?? '';
        await http
            .put(
              Uri.parse('${AppConfig.baseUrl}/users/emergency-contacts/$contactId'),
              headers: headers,
              body: jsonEncode({
                'name': name,
                'relationship': relation.isEmpty ? 'Keluarga' : relation,
                'phone_number': phone,
                'is_primary': isPrimary,
              }),
            )
            .timeout(const Duration(seconds: 4));
      } else {
        // CREATE new contact via POST
        await http
            .post(
              Uri.parse('${AppConfig.baseUrl}/users/emergency-contacts'),
              headers: headers,
              body: jsonEncode({
                'name': name,
                'relationship': relation.isEmpty ? 'Keluarga' : relation,
                'phone_number': phone,
                'is_primary': isPrimary,
              }),
            )
            .timeout(const Duration(seconds: 4));
      }
      _loadContacts();
    } catch (_) {}
  }

  Future<void> _deleteContactFromBackend(Map<String, dynamic> contact) async {
    final contactId = contact['id']?.toString();
    setState(() {
      _contacts.removeWhere((c) => c['id'] == contact['id']);
      if (contact['isPrimary'] == true && _contacts.isNotEmpty) {
        _contacts.first['isPrimary'] = true;
      }
    });

    if (contactId != null && contactId.length > 5) {
      try {
        final headers = await AppConfig.getAuthHeaders();
        await http
            .delete(
              Uri.parse('${AppConfig.baseUrl}/users/emergency-contacts/$contactId'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
    }
  }



  void _showContactFormDialog({Map<String, dynamic>? contactToEdit}) {
    final isEditing = contactToEdit != null;
    final nameController =
        TextEditingController(text: isEditing ? contactToEdit['name'] : '');
    final relationController =
        TextEditingController(text: isEditing ? contactToEdit['relation'] : '');
    final phoneController =
        TextEditingController(text: isEditing ? contactToEdit['phone'] : '');
    bool isPrimary = isEditing ? (contactToEdit['isPrimary'] ?? false) : false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isEditing
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : const Color(0xFFFFDCDD),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isEditing
                                  ? Icons.edit_note_rounded
                                  : Icons.person_add_alt_1_rounded,
                              color: isEditing
                                  ? AppColors.primary
                                  : const Color(0xFFD32F2F),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing
                                      ? 'Edit Kontak Darurat'
                                      : 'Tambah Kontak Baru',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Orang terpercaya untuk situasi darurat',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.textLight,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 16),

                      // Input 1: Nama Lengkap
                      _buildFormFieldLabel(
                        icon: Icons.badge_outlined,
                        label: 'NAMA LENGKAP',
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'Masukkan nama kontak...',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Input 2: Hubungan / Peran
                      _buildFormFieldLabel(
                        icon: Icons.favorite_outline_rounded,
                        label: 'HUBUNGAN / PERAN',
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: relationController,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: Ibu, Pasangan, Dokter...',
                          prefixIcon: Icons.family_restroom_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Input 3: Nomor Telepon
                      _buildFormFieldLabel(
                        icon: Icons.phone_outlined,
                        label: 'NOMOR TELEPON / WHATSAPP',
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: 0812-3456-7890',
                          prefixIcon: Icons.phone_iphone_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Switch: Kontak Utama
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isPrimary
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPrimary
                                ? const Color(0xFF86EFAC).withValues(alpha: 0.6)
                                : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isPrimary
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: isPrimary
                                    ? const Color(0xFF047857)
                                    : AppColors.textLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jadikan Kontak Utama',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Prioritas panggilan darurat pertama',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isPrimary,
                              activeThumbColor: const Color(0xFF10B981),
                              activeTrackColor: const Color(0xFFD1FAE5),
                              onChanged: (val) {
                                setDialogState(() {
                                  isPrimary = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              icon: Icon(
                                isEditing
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                size: 18,
                              ),
                              label: Text(
                                isEditing ? 'Simpan Perubahan' : 'Tambah Kontak',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () {
                                final name = nameController.text.trim();
                                final relation = relationController.text.trim();
                                final phone = phoneController.text.trim();

                                if (name.isEmpty || phone.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Nama dan nomor telepon wajib diisi'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pop(context);
                                _saveContactToBackend(
                                  name: name,
                                  relation: relation,
                                  phone: phone,
                                  isPrimary: isPrimary,
                                  contactToEdit: isEditing ? contactToEdit : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },

        );

      },

    );

  }

  Widget _buildFormFieldLabel({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textLight),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textLight,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textLight,
      ),
      prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.textSecondary),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  void _confirmDeleteContact(Map<String, dynamic> contact) {

    showDialog(

      context: context,

      builder: (context) {

        return AlertDialog(

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

          title: Text(

            'Hapus Kontak Darurat?',

            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),

          ),

          content: Text(

            'Apakah Anda yakin ingin menghapus "${contact['name']}" dari daftar kontak darurat?',

            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),

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
                _deleteContactFromBackend(contact);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kontak "${contact['name']}" telah dihapus.'),
                  ),
                );
              },

              child: Text(

                'Hapus',

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

              // Header Bar with Back Button Only (Cleaned App Bar)
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
                      Text(
                        'Kontak Darurat Krisis',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFEBECEF)),



              // Scrollable Content

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      // Info Banner Card
                      StaggeredEntrance(
                        index: 1,
                        child: GlassCard(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFDCDD),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFFD32F2F),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'RENCANA KESELAMATAN KRISIS',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textLight,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Kontak ini siap dihubungi secara instan saat sistem LUNA mendeteksi indikasi krisis emosional tinggi.',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // List Header Title (Cleaned header without duplicate button)
                      StaggeredEntrance(
                        index: 2,
                        child: Text(
                          'DAFTAR KONTAK (${_contacts.length})',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),



                      // Contacts List Items
                      StaggeredEntrance(
                        index: 3,
                        child: _isLoading
                            ? const _EmergencyContactsSkeletonLoader()
                            : _contacts.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                                      child: Column(
                                        children: [
                                          const Icon(Icons.contacts_outlined, size: 48, color: AppColors.textLight),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Belum ada kontak darurat',
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
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _contacts.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final contact = _contacts[index];
                                      final bool isPrimary = contact['isPrimary'] == true;
                                      return GlassCard(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(18),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: isPrimary ? const Color(0xFFFFDCDD) : AppColors.primaryContainer,
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                  child: Icon(
                                                    isPrimary ? Icons.star_rounded : Icons.person_outline,
                                                    color: isPrimary ? const Color(0xFFD32F2F) : AppColors.primary,
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              contact['name'] ?? '',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 15,
                                                                fontWeight: FontWeight.w700,
                                                                color: AppColors.textPrimary,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          if (isPrimary) ...[
                                                            const SizedBox(width: 8),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFFFFEBEE),
                                                                borderRadius: BorderRadius.circular(6),
                                                                border: Border.all(color: const Color(0xFFFFCDD2)),
                                                              ),
                                                              child: Text(
                                                                'UTAMA',
                                                                style: GoogleFonts.inter(
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.w800,
                                                                  color: const Color(0xFFD32F2F),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        contact['relationship'] ?? '',
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
                                            const SizedBox(height: 14),
                                            const Divider(height: 1, color: Color(0xFFF0F1F5)),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () => _copyToClipboard(contact['phone'] ?? '', 'Nomor Telepon'),
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                                                          const SizedBox(width: 8),
                                                          Flexible(
                                                            child: Text(
                                                              contact['phone'] ?? '',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.w600,
                                                                color: AppColors.textPrimary,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                                  color: AppColors.primary,
                                                  onPressed: () => _showContactFormDialog(contactToEdit: contact),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 20),
                                                  color: const Color(0xFFD32F2F),
                                                  onPressed: () => _confirmDeleteContact(contact),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                      ),

                      const SizedBox(height: 28),

                      // Official Emergency & Counseling Hotlines Section
                      StaggeredEntrance(
                        index: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE4DCFF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.support_agent,
                                    size: 16,
                                    color: Color(0xFF6C5CE7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Hotline Resmi 24 Jam',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildOfficialHotlineCard(
                              title: 'Layanan SEJIWA (Kemenkes & BNPB)',
                              desc: 'Konseling psikologis gratis dari pemerintah RI',
                              number: '119',
                              displayNumber: '119 (Ekstensi 8)',
                              icon: Icons.local_hospital_outlined,
                              accentColor: const Color(0xFF6C5CE7),
                              badgeBg: const Color(0xFFF3F0FF),
                            ),
                            const SizedBox(height: 10),
                            _buildOfficialHotlineCard(
                              title: 'LISA - Sahabat Jiwa',
                              desc: 'Hotline pencegahan krisis & WhatsApp 24 Jam',
                              number: '08113855472',
                              displayNumber: '0811-3855-472',
                              icon: Icons.phone_in_talk_outlined,
                              accentColor: const Color(0xFF00CEC9),
                              badgeBg: const Color(0xFFD7F3FF),
                            ),
                            const SizedBox(height: 10),
                            _buildOfficialHotlineCard(
                              title: 'Nomor Darurat Nasional Terpadu',
                              desc: 'Panggilan darurat nasional bebas pulsa (Polisi/Damkar/Medis)',
                              number: '112',
                              displayNumber: '112',
                              icon: Icons.emergency_outlined,
                              accentColor: const Color(0xFFD32F2F),
                              badgeBg: const Color(0xFFFFDCDD),
                            ),
                            const SizedBox(height: 10),
                            _buildOfficialHotlineCard(
                              title: 'Halo Kemenkes',
                              desc: 'Informasi fasilitas kesehatan & layanan rujukan',
                              number: '1500567',
                              displayNumber: '1500-567',
                              icon: Icons.info_outline,
                              accentColor: const Color(0xFF0984E3),
                              badgeBg: const Color(0xFFDFE6E9),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),

                    ],

                  ),

                ),

              ),

            ],

          ),

        ),

      ),
      // Single Efficient Floating Action Button (FAB)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactFormDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tambah Kontak',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildOfficialHotlineCard({
    required String title,
    required String desc,
    required String number,
    required String displayNumber,
    required IconData icon,
    required Color accentColor,
    required Color badgeBg,
  }) {
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 14),
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
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayNumber,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
            tooltip: 'Salin nomor',
            onPressed: () => _copyToClipboard(number, title),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton loader for Emergency Contacts list.
class _EmergencyContactsSkeletonLoader extends StatelessWidget {
  const _EmergencyContactsSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmerHost(
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GlassCard(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SkeletonBox(width: 44, height: 44, borderRadius: 14),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletonLine(width: 140, height: 16),
                            SizedBox(height: 6),
                            SkeletonLine(width: 90, height: 12),
                          ],
                        ),
                      ),
                      const SkeletonBox(width: 60, height: 22, borderRadius: 6),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      SkeletonBox(width: 130, height: 28, borderRadius: 8),
                      Spacer(),
                      SkeletonCircle(size: 32),
                      SizedBox(width: 8),
                      SkeletonCircle(size: 32),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
