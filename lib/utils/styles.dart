import 'package:flutter/material.dart';

// Paleta de colores principal
const Color backgroundColor = Color(0xFFFAFAFA);
const Color surfaceColor = Colors.white;
const Color primaryColor = Color(
  0xFFA0522D,
); // Marrón vino más claro y elegante
const Color primaryLightColor = Color(0xFFA0522D);
const Color primaryDarkColor = Color(0xFF654321);
const Color secondaryColor = Color(0xFFD2691E); // Naranja terroso
const Color accentColor = Color(0xFFCD853F); // Beige dorado

// Colores de texto
const Color textPrimaryColor = Color(0xFF2C2C2C);
const Color textSecondaryColor = Color(0xFF666666);
const Color textLightColor = Color(0xFF999999);

// Colores de estado
const Color successColor = Color(0xFF4CAF50);
const Color errorColor = Color(0xFFE53E3E);
const Color warningColor = Color(0xFFFF9800);
const Color infoColor = Color(0xFF2196F3);

// Colores de fondo
const Color cardBackgroundColor = Colors.white;
const Color dividerColor = Color(0xFFE0E0E0);
const Color shadowColor = Color(0x1A000000);

// Espaciado
const double spacingXS = 4.0;
const double spacingS = 8.0;
const double spacingM = 16.0;
const double spacingL = 24.0;
const double spacingXL = 32.0;

// Bordes redondeados
const double radiusS = 8.0;
const double radiusM = 12.0;
const double radiusL = 16.0;
const double radiusXL = 24.0;

// Elevación/sombras
const double elevationS = 2.0;
const double elevationM = 4.0;
const double elevationL = 8.0;

// Tipografía
const TextStyle heading1Style = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: textPrimaryColor,
  height: 1.2,
);

const TextStyle heading2Style = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  color: textPrimaryColor,
  height: 1.3,
);

const TextStyle heading3Style = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: textPrimaryColor,
  height: 1.3,
);

const TextStyle bodyLargeStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: textPrimaryColor,
  height: 1.5,
);

const TextStyle bodyMediumStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.normal,
  color: textPrimaryColor,
  height: 1.4,
);

const TextStyle bodySmallStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.normal,
  color: textSecondaryColor,
  height: 1.3,
);

const TextStyle buttonTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

const TextStyle appBarTitleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: Colors.white,
  height: 1.3,
);

// Estilos de componentes
BoxDecoration cardDecoration = BoxDecoration(
  color: cardBackgroundColor,
  borderRadius: BorderRadius.circular(radiusM),
  boxShadow: [
    BoxShadow(
      color: shadowColor,
      blurRadius: elevationM,
      offset: const Offset(0, 2),
    ),
  ],
);

BoxDecoration inputDecoration = BoxDecoration(
  color: surfaceColor,
  borderRadius: BorderRadius.circular(radiusS),
  border: Border.all(color: dividerColor, width: 1),
);

// Compatibilidad con código existente
const Color textColor = textPrimaryColor;
