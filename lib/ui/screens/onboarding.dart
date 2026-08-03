/// Introducción de primera vez, incluida la elección de interfaz.
library;

import 'package:flutter/material.dart';

import '../strings.dart';

/// Introducción de primera vez: 3 pasos honestos (qué es, qué NO es,
/// privacidad) y un cuarto donde se elige la interfaz. Se muestra una vez;
/// el flag vive en la config.
///
/// La elección de interfaz llega ANTES de la primera pantalla real a
/// propósito: quien instala esto por miedo a que le hayan intervenido el
/// teléfono no debería estrellarse contra diez pestañas técnicas. La opción
/// básica viene marcada, así que pulsar "Empezar" sin leer da el resultado
/// menos abrumador.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.strings,
    required this.onDone,
  });

  final AppStrings strings;

  /// Recibe el modo de visualización elegido (`simple` por defecto).
  final ValueChanged<String> onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  /// Preselección deliberada: la interfaz básica.
  String _viewMode = 'simple';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final theme = Theme.of(context);
    final pages = <Widget>[
      _intro(theme, Icons.radar, s.onboardTitle1, s.onboardBody1),
      _intro(theme, Icons.block, s.onboardTitle2, s.onboardBody2),
      _intro(theme, Icons.lock_outline, s.onboardTitle3, s.onboardBody3),
      _modeChooser(theme, s),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, i) => pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_page < pages.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    } else {
                      widget.onDone(_viewMode);
                    }
                  },
                  child: Text(
                    _page < pages.length - 1 ? s.onboardNext : s.onboardStart,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intro(ThemeData theme, IconData icon, String title, String body) =>
      Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(body, textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _modeChooser(ThemeData theme, AppStrings s) {
    final options = <(String, String, String, IconData)>[
      ('simple', s.viewModeSimple, s.viewModeSimpleHint, Icons.filter_1),
      ('normal', s.viewModeNormal, s.viewModeNormalHint, Icons.filter_2),
      ('advanced', s.viewModeAdvanced, s.viewModeAdvancedHint, Icons.filter_3),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tune, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            s.onboardTitleMode,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(s.onboardBodyMode, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          for (final (mode, label, hint, icon) in options)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: _viewMode == mode
                  ? theme.colorScheme.primaryContainer
                  : null,
              child: ListTile(
                onTap: () => setState(() => _viewMode = mode),
                selected: _viewMode == mode,
                leading: Icon(icon),
                trailing: Icon(
                  _viewMode == mode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Row(
                  children: [
                    Flexible(child: Text(label)),
                    if (mode == 'simple') ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          s.onboardModeRecommended,
                          style: theme.textTheme.labelSmall,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
                subtitle: Text(hint),
              ),
            ),
        ],
      ),
    );
  }
}
