/// Pestaña Acerca: versión, autor, filosofía y privacidad local.
library;

import 'package:flutter/material.dart';

import '../strings.dart';
import '../widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    required this.strings,
    required this.productName,
    required this.version,
    required this.author,
    required this.license,
    required this.repository,
    this.crashLog,
    this.onShareCrashLog,
    this.onClearCrashLog,
  });

  final AppStrings strings;
  final String productName;
  final String version;
  final String author;
  final String license;
  final String repository;

  /// Contenido del registro local de errores (null si no hay).
  final String? crashLog;
  final VoidCallback? onShareCrashLog;
  final VoidCallback? onClearCrashLog;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      SectionCard(
        title: productName,
        children: [
          InfoRow(label: strings.aboutVersion, value: version),
          InfoRow(label: strings.aboutAuthor, value: author),
          InfoRow(label: strings.aboutLicense, value: license),
          const SizedBox(height: 6),
          Text(repository, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      SectionCard(
        title: strings.aboutPhilosophyTitle,
        children: [Text(strings.aboutPhilosophyBody)],
      ),
      SectionCard(
        title: strings.aboutPrivacyTitle,
        children: [Text(strings.aboutPrivacyBody)],
      ),
      SectionCard(
        title: strings.diagTitle,
        children: [
          Text(strings.diagNote, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          if (crashLog == null)
            Text(strings.diagNone)
          else ...[
            Text(
              crashLog!.length > 600
                  ? '${crashLog!.substring(0, 600)}…'
                  : crashLog!,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onShareCrashLog != null)
                  TextButton.icon(
                    icon: const Icon(Icons.share, size: 16),
                    label: Text(strings.diagShare),
                    onPressed: onShareCrashLog,
                  ),
                if (onClearCrashLog != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text(strings.diagClear),
                    onPressed: onClearCrashLog,
                  ),
              ],
            ),
          ],
        ],
      ),
    ],
  );
}
