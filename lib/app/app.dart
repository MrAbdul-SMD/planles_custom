import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:planles_custom/core/locale_provider.dart';
import 'package:planles_custom/l10n/app_localizations.dart';

import 'theme.dart';

class PlanlesApp extends ConsumerWidget {
  const PlanlesApp({super.key, required this.router});

  final RouterConfig<Object> router;

  /// Above this width the UI is capped and centred so desktop/macOS windows
  /// don't render mobile layouts stretched across the whole screen.
  static const _wideBreakpoint = 900.0;
  static const _maxContentWidth = 760.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `null` → follow the system language.
    final override = ref.watch(localeOverrideProvider).value;

    return MaterialApp.router(
      title: 'Planles',
      debugShowCheckedModeBanner: false,
      locale: override,
      supportedLocales: const [Locale('nl'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        _IntlLocaleDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= _wideBreakpoint) return content;
            return ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: content,
                ),
              ),
            );
          },
        );
      },
      routerConfig: router,
    );
  }
}

/// Points `intl` (`DateFormat`, `NumberFormat`) at the locale the app is
/// currently displaying, so `F.money(...)` / `F.time(...)` and friends format
/// consistently without threading a locale through every call site.
class _IntlLocaleDelegate extends LocalizationsDelegate<Locale> {
  const _IntlLocaleDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Locale> load(Locale locale) {
    Intl.defaultLocale = locale.toLanguageTag();
    return SynchronousFuture(locale);
  }

  @override
  bool shouldReload(_IntlLocaleDelegate old) => false;
}
