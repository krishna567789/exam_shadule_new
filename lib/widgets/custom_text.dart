import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CustomTextStyle {
  regular, // Rajdhani
  heading, // Orbitron (futuristic cyber headings)
  mono,    // Share Tech Mono (telemetry/numbers)
}

class CustomText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final CustomTextStyle styleType;
  final double? letterSpacing;
  final List<Shadow>? shadows;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const CustomText(
    this.text, {
    super.key,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.styleType = CustomTextStyle.regular,
    this.letterSpacing,
    this.shadows,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  // Helper factory constructors for convenience
  factory CustomText.regular(
    String text, {
    Key? key,
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    List<Shadow>? shadows,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return CustomText(
      text,
      key: key,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      styleType: CustomTextStyle.regular,
      letterSpacing: letterSpacing,
      shadows: shadows,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  factory CustomText.heading(
    String text, {
    Key? key,
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    List<Shadow>? shadows,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return CustomText(
      text,
      key: key,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      styleType: CustomTextStyle.heading,
      letterSpacing: letterSpacing,
      shadows: shadows,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  factory CustomText.mono(
    String text, {
    Key? key,
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    List<Shadow>? shadows,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return CustomText(
      text,
      key: key,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      styleType: CustomTextStyle.mono,
      letterSpacing: letterSpacing,
      shadows: shadows,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle;

    switch (styleType) {
      case CustomTextStyle.heading:
        textStyle = GoogleFonts.outfit(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight ?? FontWeight.bold,
          letterSpacing: letterSpacing ?? 1.2,
          shadows: shadows,
        );
        break;
      case CustomTextStyle.mono:
        textStyle = GoogleFonts.outfit(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          shadows: shadows,
        );
        break;
      case CustomTextStyle.regular:
      default:
        textStyle = GoogleFonts.outfit(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          shadows: shadows,
        );
        break;
    }

    return Text(
      text,
      style: textStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
