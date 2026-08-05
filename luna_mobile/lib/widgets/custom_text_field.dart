import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';



class CustomPillTextField extends StatefulWidget {

  final String hintText;

  final IconData prefixIcon;

  final bool isPassword;

  final TextEditingController? controller;

  final TextInputType keyboardType;



  const CustomPillTextField({

    super.key,

    required this.hintText,

    required this.prefixIcon,

    this.isPassword = false,

    this.controller,

    this.keyboardType = TextInputType.text,

  });



  @override

  State<CustomPillTextField> createState() => _CustomPillTextFieldState();

}



class _CustomPillTextFieldState extends State<CustomPillTextField> {

  bool _obscureText = true;



  @override

  Widget build(BuildContext context) {

    return Container(

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(999),

        border: Border.all(color: Colors.grey.shade300, width: 1.2),

      ),

      child: TextField(

        controller: widget.controller,

        obscureText: widget.isPassword ? _obscureText : false,

        keyboardType: widget.keyboardType,

        style: GoogleFonts.inter(

          fontSize: 15,

          color: AppColors.textPrimary,

        ),

        decoration: InputDecoration(

          hintText: widget.hintText,

          hintStyle: GoogleFonts.inter(

            fontSize: 15,

            color: AppColors.textLight,

          ),

          prefixIcon: Icon(

            widget.prefixIcon,

            color: AppColors.textSecondary,

            size: 20,

          ),

          suffixIcon: widget.isPassword

              ? IconButton(

                  icon: Icon(

                    _obscureText

                        ? Icons.visibility_off_outlined

                        : Icons.visibility_outlined,

                    color: AppColors.textSecondary,

                    size: 20,

                  ),

                  onPressed: () {

                    setState(() {

                      _obscureText = !_obscureText;

                    });

                  },

                )

              : null,

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(

            horizontal: 20,

            vertical: 16,

          ),

        ),

      ),

    );

  }

}

