import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Paleta de colores principal (Light Premium - Elegancia Clásica)
const Color backgroundColor = Color(0xFFFCFCFC); // Blanco roto
const Color surfaceColor = Colors.white; // Blanco puro para tarjetas
const Color primaryColor = Color(0xFF722F37); // Rojo Burdeos / Bordeaux
const Color primaryLightColor = Color(0xFF904C55);
const Color primaryDarkColor = Color(0xFF4A1C24);
const Color secondaryColor = Color(0xFFD4AF37); // Dorado / Champagne
const Color accentColor = Color(0xFFF3E5AB); // Vainilla suave para fondos ligeros

// Colores de texto
const Color textPrimaryColor = Color(0xFF1A1A1A); // Gris muy oscuro, casi negro
const Color textSecondaryColor = Color(0xFF6B6B6B); // Gris medio
const Color textLightColor = Color(0xFFA3A3A3); // Gris claro

// Colores de estado
const Color successColor = Color(0xFF2E7D32);
const Color errorColor = Color(0xFFD32F2F);
const Color warningColor = Color(0xFFF57C00);
const Color infoColor = Color(0xFF0288D1);

// Colores de fondo y UI
const Color cardBackgroundColor = Colors.white;
const Color dividerColor = Color(0xFFEBEBEB);
const Color shadowColor = Color(0x0F000000); // Sombra extra suave (glow sutil)

// Espaciado
const double spacingXS = 4.0;
const double spacingS = 8.0;
const double spacingM = 16.0;
const double spacingL = 24.0;
const double spacingXL = 32.0;

// Bordes redondeados (Más modernos)
const double radiusS = 12.0;
const double radiusM = 16.0;
const double radiusL = 24.0;
const double radiusXL = 32.0;

// Elevación/sombras
const double elevationS = 4.0;
const double elevationM = 8.0;
const double elevationL = 16.0;

// Tipografía - usando Google Fonts
TextStyle get heading1Style => GoogleFonts.playfairDisplay(
  fontSize: 32,
  fontWeight: FontWeight.w700,
  color: textPrimaryColor,
  height: 1.2,
);

TextStyle get heading2Style => GoogleFonts.playfairDisplay(
  fontSize: 26,
  fontWeight: FontWeight.w600,
  color: textPrimaryColor,
  height: 1.3,
);

TextStyle get heading3Style => GoogleFonts.playfairDisplay(
  fontSize: 22,
  fontWeight: FontWeight.w600,
  color: textPrimaryColor,
  height: 1.3,
);

TextStyle get bodyLargeStyle => GoogleFonts.inter(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: textPrimaryColor,
  height: 1.5,
);

TextStyle get bodyMediumStyle => GoogleFonts.inter(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: textPrimaryColor,
  height: 1.5,
);

TextStyle get bodySmallStyle => GoogleFonts.inter(
  fontSize: 13,
  fontWeight: FontWeight.w400,
  color: textSecondaryColor,
  height: 1.4,
);

TextStyle get buttonTextStyle => GoogleFonts.inter(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

TextStyle get appBarTitleStyle => GoogleFonts.playfairDisplay(
  fontSize: 22,
  fontWeight: FontWeight.w600,
  color: Colors.white,
  height: 1.3,
);

// Estilos de componentes
BoxDecoration get cardDecoration => BoxDecoration(
  color: cardBackgroundColor,
  borderRadius: BorderRadius.circular(radiusM),
  boxShadow: [
    BoxShadow(
      color: shadowColor,
      blurRadius: elevationL, // Sombra más grande y difusa
      offset: const Offset(0, 4), // Ligeramente desplazada hacia abajo
    ),
  ],
);

BoxDecoration get inputDecoration => BoxDecoration(
  color: surfaceColor,
  borderRadius: BorderRadius.circular(radiusS),
  border: Border.all(color: dividerColor, width: 1.5), // Borde ligeramente más notorio
);

// Compatibilidad con código existente
const Color textColor = textPrimaryColor;
