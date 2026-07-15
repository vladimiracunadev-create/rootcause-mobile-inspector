/// Tema Material 3 — paleta forense: azul profundo + semáforo.
library;

import 'package:flutter/material.dart';

import '../core/models.dart';

const severityGreen = Color(0xFF2E9E5B);
const severityYellow = Color(0xFFC9A227);
const severityRed = Color(0xFFC0392B);

Color severityColor(Severity s) => switch (s) {
  Severity.normal => severityGreen,
  Severity.warning => severityYellow,
  Severity.critical => severityRed,
};

ThemeData rootCauseDarkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF4FA3D1),
    brightness: Brightness.dark,
    surface: const Color(0xFF122B38),
  ),
  scaffoldBackgroundColor: const Color(0xFF0B1F2A),
);

ThemeData rootCauseLightTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF16607F),
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFF4F8FA),
);
