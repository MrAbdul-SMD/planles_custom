import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme.dart';

class PlanlesApp extends StatelessWidget {
  const PlanlesApp({super.key, required this.router});

  final RouterConfig<Object> router;

  /// Above this width the UI is capped and centred so desktop/macOS windows
  /// don't render mobile layouts stretched across the whole screen.
  static const _wideBreakpoint = 900.0;
  static const _maxContentWidth = 760.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Planles',
      debugShowCheckedModeBanner: false,
      locale: const Locale('nl'),
      supportedLocales: const [Locale('nl'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // Keeps the whole app (routes, dialogs, snackbars) inside a centred,
      // phone-sized column on wide windows.
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
