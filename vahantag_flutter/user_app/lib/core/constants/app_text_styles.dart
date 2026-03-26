import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle heading1 = GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary);
  static TextStyle heading2 = GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static TextStyle heading3 = GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle heading4 = GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle body1 = GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static TextStyle body2 = GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle caption = GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle button = GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white);
  static TextStyle label = GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle white1 = GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.white);
  static TextStyle whiteHeading = GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.white);
  static TextStyle tagCode = GoogleFonts.robotoMono(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 2);
}
