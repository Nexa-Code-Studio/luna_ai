import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/custom_button.dart';

import '../widgets/glass_card.dart';



class EmergencyContactsScreen extends StatefulWidget {

  const EmergencyContactsScreen({super.key});



  @override

  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();

}



class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {

  final List<Map<String, dynamic>> _contacts = [

    {

      'id': '1',

      'name': 'Budi Utami',

      'relation': 'Ibu Kandung',

      'phone': '+62 812-3456-7890',

      'isPrimary': true,

    },

    {

      'id': '2',

      'name': 'Dr. Rini Puspita',

      'relation': 'Psikiater / Konselor',

      'phone': '+62 857-1122-3344',

      'isPrimary': false,

    },

    {

      'id': '3',

      'name': 'Layanan Krisis Kemenkes',

      'relation': 'Hotline Darurat 24 Jam',

      'phone': '119',

      'isPrimary': false,

    },

  ];



  void _showContactFormDialog({Map<String, dynamic>? contactToEdit}) {

    final isEditing = contactToEdit != null;

    final nameController = TextEditingController(text: isEditing ? contactToEdit['name'] : '');

    final relationController =

        TextEditingController(text: isEditing ? contactToEdit['relation'] : '');

    final phoneController = TextEditingController(text: isEditing ? contactToEdit['phone'] : '');

    bool isPrimary = isEditing ? (contactToEdit['isPrimary'] ?? false) : false;



    showDialog(

      context: context,

      builder: (context) {

        return StatefulBuilder(

          builder: (context, setDialogState) {

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

                      Icons.contact_phone_outlined,

                      color: Color(0xFFD32F2F),

                      size: 20,

                    ),

                  ),

                  const SizedBox(width: 10),

                  Text(

                    isEditing ? 'Edit Kontak Darurat' : 'Tambah Kontak Baru',

                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),

                  ),

                ],

              ),

              content: SingleChildScrollView(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      'NAMA KONTAK',

                      style: GoogleFonts.inter(

                        fontSize: 10,

                        fontWeight: FontWeight.w700,

                        color: AppColors.textLight,

                      ),

                    ),

                    const SizedBox(height: 4),

                    TextField(

                      controller: nameController,

                      style: GoogleFonts.inter(fontSize: 14),

                      decoration: InputDecoration(

                        hintText: 'Masukkan nama...',

                        filled: true,

                        fillColor: const Color(0xFFF4F6FB),

                        border: OutlineInputBorder(

                          borderRadius: BorderRadius.circular(12),

                          borderSide: BorderSide.none,

                        ),

                        contentPadding:

                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

                      ),

                    ),

                    const SizedBox(height: 12),

                    Text(

                      'HUBUNGAN / PERAN',

                      style: GoogleFonts.inter(

                        fontSize: 10,

                        fontWeight: FontWeight.w700,

                        color: AppColors.textLight,

                      ),

                    ),

                    const SizedBox(height: 4),

                    TextField(

                      controller: relationController,

                      style: GoogleFonts.inter(fontSize: 14),

                      decoration: InputDecoration(

                        hintText: 'Ibu / Dokter / Sahabat...',

                        filled: true,

                        fillColor: const Color(0xFFF4F6FB),

                        border: OutlineInputBorder(

                          borderRadius: BorderRadius.circular(12),

                          borderSide: BorderSide.none,

                        ),

                        contentPadding:

                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

                      ),

                    ),

                    const SizedBox(height: 12),

                    Text(

                      'NOMOR TELEPON / WHATSAPP',

                      style: GoogleFonts.inter(

                        fontSize: 10,

                        fontWeight: FontWeight.w700,

                        color: AppColors.textLight,

                      ),

                    ),

                    const SizedBox(height: 4),

                    TextField(

                      controller: phoneController,

                      keyboardType: TextInputType.phone,

                      style: GoogleFonts.inter(fontSize: 14),

                      decoration: InputDecoration(

                        hintText: '+62 812-xxxx...',

                        filled: true,

                        fillColor: const Color(0xFFF4F6FB),

                        border: OutlineInputBorder(

                          borderRadius: BorderRadius.circular(12),

                          borderSide: BorderSide.none,

                        ),

                        contentPadding:

                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

                      ),

                    ),

                    const SizedBox(height: 12),

                    Row(

                      children: [

                        Expanded(

                          child: Text(

                            'Jadikan Kontak Utama',

                            style: GoogleFonts.inter(

                              fontSize: 13,

                              fontWeight: FontWeight.w600,

                              color: AppColors.textPrimary,

                            ),

                          ),

                        ),

                        Switch(

                          value: isPrimary,

                          activeThumbColor: AppColors.primary,

                          onChanged: (val) {

                            setDialogState(() {

                              isPrimary = val;

                            });

                          },

                        ),

                      ],

                    ),

                  ],

                ),

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

                    final name = nameController.text.trim();

                    final relation = relationController.text.trim();

                    final phone = phoneController.text.trim();



                    if (name.isNotEmpty && phone.isNotEmpty) {

                      setState(() {

                        if (isPrimary) {

                          for (var c in _contacts) {

                            c['isPrimary'] = false;

                          }

                        }



                        if (isEditing) {

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

                      Navigator.pop(context);

                    }

                  },

                  child: Text(

                    isEditing ? 'Simpan' : 'Tambah',

                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),

                  ),

                ),

              ],

            );

          },

        );

      },

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

                setState(() {

                  _contacts.removeWhere((c) => c['id'] == contact['id']);

                  if (contact['isPrimary'] == true && _contacts.isNotEmpty) {

                    _contacts.first['isPrimary'] = true;

                  }

                });

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

              const Divider(height: 1, color: Color(0xFFEBECEF)),



              // Scrollable Content

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      // Info Banner Card

                      GlassCard(

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

                      const SizedBox(height: 20),



                      // List Header Title (Cleaned header without duplicate button)

                      Text(

                        'DAFTAR KONTAK (${_contacts.length})',

                        style: GoogleFonts.inter(

                          fontSize: 11,

                          fontWeight: FontWeight.w700,

                          color: AppColors.textLight,

                          letterSpacing: 0.8,

                        ),

                      ),

                      const SizedBox(height: 12),



                      // Contacts List Items

                      if (_contacts.isEmpty)

                        Center(

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

                      else

                        ListView.separated(

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

                                          color: isPrimary

                                              ? const Color(0xFFFFDCDD)

                                              : AppColors.primaryContainer,

                                          shape: BoxShape.circle,

                                        ),

                                        child: Icon(

                                          isPrimary ? Icons.star_rounded : Icons.person_outline,

                                          color: isPrimary ? const Color(0xFFD32F2F) : AppColors.primary,

                                          size: 22,

                                        ),

                                      ),

                                      const SizedBox(width: 14),

                                      Expanded(

                                        child: Column(

                                          crossAxisAlignment: CrossAxisAlignment.start,

                                          children: [

                                            Row(

                                              children: [

                                                Expanded(

                                                  child: Text(

                                                    contact['name'],

                                                    maxLines: 1,

                                                    overflow: TextOverflow.ellipsis,

                                                    style: GoogleFonts.inter(

                                                      fontSize: 15,

                                                      fontWeight: FontWeight.w700,

                                                      color: AppColors.textPrimary,

                                                    ),

                                                  ),

                                                ),

                                                if (isPrimary) ...[

                                                  const SizedBox(width: 6),

                                                  Container(

                                                    padding: const EdgeInsets.symmetric(

                                                      horizontal: 8,

                                                      vertical: 2,

                                                    ),

                                                    decoration: BoxDecoration(

                                                      color: const Color(0xFFFFDCDD),

                                                      borderRadius: BorderRadius.circular(999),

                                                    ),

                                                    child: Text(

                                                      'KONTAK UTAMA',

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

                                              '${contact['relation']} • ${contact['phone']}',

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

                                  const Divider(height: 1, color: Color(0xFFEBECEF)),

                                  const SizedBox(height: 10),

                                  Row(

                                    children: [

                                      // Test Call Action Button

                                      Expanded(

                                        child: CustomPillButton(

                                          text: 'Uji Panggilan',

                                          height: 38,

                                          isOutline: true,

                                          onPressed: () {

                                            ScaffoldMessenger.of(context).showSnackBar(

                                              SnackBar(

                                                content: Text(

                                                  'Uji panggilan darurat ke ${contact['name']} (${contact['phone']})...',

                                                ),

                                                backgroundColor: const Color(0xFFD32F2F),

                                              ),

                                            );

                                          },

                                        ),

                                      ),

                                      const SizedBox(width: 10),

                                      // Edit Icon Button

                                      IconButton(

                                        icon: const Icon(Icons.edit_outlined, size: 20),

                                        color: AppColors.primary,

                                        onPressed: () => _showContactFormDialog(contactToEdit: contact),

                                      ),

                                      // Delete Icon Button

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

                      const SizedBox(height: 24),

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

}

