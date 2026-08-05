import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/glass_card.dart';



class AiConversationScreen extends StatefulWidget {

  const AiConversationScreen({super.key});



  @override

  State<AiConversationScreen> createState() => _AiConversationScreenState();

}



class _AiConversationScreenState extends State<AiConversationScreen> {

  final List<Map<String, dynamic>> _messages = [

    {

      'isUser': true,

      'text': 'I feel overwhelmed with my college tasks.',

      'time': '10:42 AM',

    },

    {

      'isUser': false,

      'text':

          'I understand that you are feeling pressured. Would you like to tell me more about what happened today?',

      'time': '10:42 AM',

    },

  ];



  final TextEditingController _textController = TextEditingController();

  bool _hasText = false;



  @override

  void initState() {

    super.initState();

    _textController.addListener(_onTextChanged);

  }



  void _onTextChanged() {

    final hasText = _textController.text.trim().isNotEmpty;

    if (hasText != _hasText) {

      setState(() {

        _hasText = hasText;

      });

    }

  }



  @override

  void dispose() {

    _textController.removeListener(_onTextChanged);

    _textController.dispose();

    super.dispose();

  }



  void _sendMessage() {

    if (_textController.text.trim().isEmpty) return;

    setState(() {

      _messages.add({

        'isUser': true,

        'text': _textController.text.trim(),

        'time': '10:43 AM',

      });

      _textController.clear();

    });

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

              // Custom App Bar

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),

                child: Row(

                  children: [

                    IconButton(

                      icon: const Icon(Icons.arrow_back),

                      color: AppColors.textPrimary,

                      onPressed: () {

                        Navigator.pop(context);

                      },

                    ),

                    // App Logo

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

                    Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          'LUNA',

                          style: GoogleFonts.inter(

                            fontSize: 15,

                            fontWeight: FontWeight.w700,

                            color: AppColors.primary,

                          ),

                        ),

                        Row(

                          children: [

                            Container(

                              width: 7,

                              height: 7,

                              decoration: const BoxDecoration(

                                shape: BoxShape.circle,

                                color: Color(0xFF4CAF50),

                              ),

                            ),

                            const SizedBox(width: 4),

                            Text(

                              'Listening...',

                              style: GoogleFonts.inter(

                                fontSize: 12,

                                color: AppColors.textLight,

                              ),

                            ),

                          ],

                        ),

                      ],

                    ),

                    const Spacer(),

                    IconButton(

                      icon: const Icon(Icons.more_vert),

                      color: AppColors.textPrimary,

                      onPressed: () {},

                    ),

                  ],

                ),

              ),

              const Divider(height: 1, color: Color(0xFFEBECEF)),



              // Messages List

              Expanded(

                child: ListView.builder(

                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

                  itemCount: _messages.length,

                  itemBuilder: (context, index) {

                    final msg = _messages[index];

                    final isUser = msg['isUser'] as bool;

                    return Align(

                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,

                      child: Container(

                        margin: const EdgeInsets.only(bottom: 16),

                        constraints: BoxConstraints(

                          maxWidth: MediaQuery.of(context).size.width * 0.75,

                        ),

                        child: Column(

                          crossAxisAlignment:

                              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,

                          children: [

                            // Message Bubble

                            isUser

                                ? Container(

                                    padding: const EdgeInsets.all(16),

                                    decoration: const BoxDecoration(

                                      color: AppColors.primary,

                                      borderRadius: BorderRadius.only(

                                        topLeft: Radius.circular(20),

                                        topRight: Radius.circular(20),

                                        bottomLeft: Radius.circular(20),

                                        bottomRight: Radius.circular(6),

                                      ),

                                    ),

                                    child: Text(

                                      msg['text'],

                                      style: GoogleFonts.inter(

                                        fontSize: 14,

                                        color: Colors.white,

                                        height: 1.4,

                                      ),

                                    ),

                                  )

                                : GlassCard(

                                    padding: const EdgeInsets.all(16),

                                    borderRadius: 20,

                                    child: Text(

                                      msg['text'],

                                      style: GoogleFonts.inter(

                                        fontSize: 14,

                                        color: AppColors.textPrimary,

                                        height: 1.4,

                                      ),

                                    ),

                                  ),

                            const SizedBox(height: 4),

                            Text(

                              msg['time'],

                              style: GoogleFonts.inter(

                                fontSize: 11,

                                color: AppColors.textLight,

                              ),

                            ),

                          ],

                        ),

                      ),

                    );

                  },

                ),

              ),



              // Stress Status Indicator Pill

              Container(

                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),

                decoration: BoxDecoration(

                  color: const Color(0xFFE0F4FB),

                  borderRadius: BorderRadius.circular(999),

                ),

                child: Row(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    const Icon(

                      Icons.show_chart,

                      size: 16,

                      color: Color(0xFF20667B),

                    ),

                    const SizedBox(width: 6),

                    Text(

                      'Stress: Moderate',

                      style: GoogleFonts.inter(

                        fontSize: 12,

                        fontWeight: FontWeight.w600,

                        color: const Color(0xFF20667B),

                      ),

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 12),



              // Floating Bottom Input Bar

              Padding(

                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

                child: Container(

                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius: BorderRadius.circular(999),

                    border: Border.all(color: Colors.grey.shade300, width: 1),

                    boxShadow: [

                      BoxShadow(

                        color: Colors.black.withValues(alpha: 0.04),

                        blurRadius: 16,

                        offset: const Offset(0, 4),

                      ),

                    ],

                  ),

                  child: Row(

                    children: [

                      IconButton(

                        icon: const Icon(Icons.add, color: AppColors.textSecondary),

                        onPressed: () {},

                      ),

                      Expanded(

                        child: TextField(

                          controller: _textController,

                          onSubmitted: (_) => _sendMessage(),

                          style: GoogleFonts.inter(

                            fontSize: 14,

                            color: AppColors.textPrimary,

                          ),

                          decoration: InputDecoration(

                            hintText: 'Type or speak to LUNA...',

                            hintStyle: GoogleFonts.inter(

                              fontSize: 14,

                              color: AppColors.textLight,

                            ),

                            border: InputBorder.none,

                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),

                          ),

                        ),

                      ),

                      IconButton(

                        icon: const Icon(Icons.mic_none, color: AppColors.primary),

                        onPressed: () {},

                      ),

                      const SizedBox(width: 4),

                      // Audio Wave / Send Button

                      GestureDetector(

                        onTap: _hasText

                            ? _sendMessage

                            : () {

                                Navigator.pushNamed(context, '/voice_call');

                              },

                        child: Container(

                          width: 44,

                          height: 44,

                          decoration: const BoxDecoration(

                            shape: BoxShape.circle,

                            color: AppColors.primary,

                          ),

                          child: Icon(

                            _hasText ? Icons.send : Icons.graphic_eq,

                            color: Colors.white,

                            size: 20,

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

      ),

    );

  }

}

