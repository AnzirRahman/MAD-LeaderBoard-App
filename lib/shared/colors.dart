import 'package:flutter/material.dart';

class AppColors {
  // Primary and secondary colors
  static const primaryColor = Color(0xFFF4F4F4);
  static const secondaryColor = Color(0xFF333333);
  static const tertiaryColor = Color.fromARGB(255, 232, 232, 232);

  // Accent colors
  static const primaryAccentColor = Color(0xFFFAA94D);
  static const secondaryAccentColor = Color(0xFFF8894B);

  // Shades
  static const darkerShade = Color(0xFF808080);
  static const lighterShade = Color(0xFF9F9F9F);

  // Background colors
  static const primaryBgColor = primaryColor;
  static const secondaryBgColor = secondaryColor;
  static const tertiaryBgColor = tertiaryColor;

  // Text colors
  static const primaryTextColor = secondaryColor;
  static const secondaryTextColor = primaryColor;

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryAccentColor, secondaryAccentColor],
  );

  static const secondaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [secondaryAccentColor, primaryAccentColor],
  );
}
