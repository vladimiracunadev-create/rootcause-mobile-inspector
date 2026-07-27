import 'package:flutter_test/flutter_test.dart';
import 'package:rootcause_mobile_inspector/ui/strings.dart';

void main() {
  group('resolveLanguage', () {
    test('código explícito conocido manda sobre el idioma del equipo', () {
      expect(
        resolveLanguage('pt', deviceLanguageCode: 'en'),
        AppLang.pt,
      );
    });

    test('vacío ("automático") toma el idioma del equipo', () {
      expect(resolveLanguage('', deviceLanguageCode: 'it'), AppLang.it);
      expect(resolveLanguage('', deviceLanguageCode: 'fr'), AppLang.fr);
    });

    test('idioma del equipo desconocido cae a inglés', () {
      expect(resolveLanguage('', deviceLanguageCode: 'de'), AppLang.en);
      expect(resolveLanguage('zz', deviceLanguageCode: 'ja'), AppLang.en);
    });
  });

  group('permissionLabel', () {
    test('traduce constantes conocidas a lenguaje humano por idioma', () {
      expect(
        const AppStrings(AppLang.es).permissionLabel('ACCESS_FINE_LOCATION'),
        'Ubicación precisa (GPS)',
      );
      expect(
        const AppStrings(AppLang.en).permissionLabel('RECORD_AUDIO'),
        'Microphone (record audio)',
      );
      expect(
        const AppStrings(AppLang.fr).permissionLabel('READ_SMS'),
        'Lire vos SMS',
      );
    });

    test('humaniza constantes desconocidas como último recurso', () {
      // Nunca muestra la constante cruda tipo "variable de programación".
      expect(
        const AppStrings(AppLang.es).permissionLabel('SOME_NEW_PERMISSION'),
        'Some new permission',
      );
    });
  });

  test('flagLabel describe las señales especiales', () {
    expect(
      const AppStrings(AppLang.es).flagLabel('sideloaded'),
      'Instalada fuera de la tienda oficial',
    );
    expect(
      const AppStrings(AppLang.it).flagLabel('overlay'),
      'Può disegnare sopra altre app',
    );
  });

  test('los cinco idiomas resuelven las pestañas sin caer al fallback', () {
    for (final lang in AppLang.values) {
      final s = AppStrings(lang);
      expect(s.tabSummary.isNotEmpty, isTrue);
      expect(s.tabFlagged.isNotEmpty, isTrue);
    }
  });
}
