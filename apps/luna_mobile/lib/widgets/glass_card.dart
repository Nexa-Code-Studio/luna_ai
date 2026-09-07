import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';



class GlassCard extends StatelessWidget {

  final Widget child;

  final EdgeInsetsGeometry? padding;

  final EdgeInsetsGeometry? margin;

  final double borderRadius;

  final Color? backgroundColor;

  final Color? borderColor;

  final double? width;

  final double? height;

  final VoidCallback? onTap;



  const GlassCard({

    super.key,

    required this.child,

    this.padding = const EdgeInsets.all(20),

    this.margin,

    this.borderRadius = 24.0,

    this.backgroundColor,

    this.borderColor,

    this.width,

    this.height,

    this.onTap,

  });



  @override

  Widget build(BuildContext context) {

    Widget cardContent = ClipRRect(

      borderRadius: BorderRadius.circular(borderRadius),

      child: BackdropFilter(

        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

        child: Container(

          width: width,

          height: height,

          padding: padding,

          decoration: BoxDecoration(

            color: backgroundColor ?? AppColors.glassBackground,

            borderRadius: BorderRadius.circular(borderRadius),

            border: Border.all(

              color: borderColor ?? AppColors.glassBorder,

              width: 1.2,

            ),

            boxShadow: [

              BoxShadow(

                color: AppColors.glassShadow,

                blurRadius: 30,

                spreadRadius: 0,

                offset: const Offset(0, 10),

              ),

            ],

          ),

          child: child,

        ),

      ),

    );



    if (margin != null) {

      cardContent = Padding(padding: margin!, child: cardContent);

    }



    if (onTap != null) {

      return GestureDetector(

        onTap: onTap,

        child: cardContent,

      );

    }



    return cardContent;

  }

}

