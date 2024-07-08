import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';
import 'main_views/main_screen.dart';

class EasyWalletApp extends StatelessWidget {
  const EasyWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'EasyWallet',
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: const MainScreen(),
    );
  }

  static TextStyle responsiveTextStyle(
      double baseSize,
      BuildContext context, {
        bool bold = false,
        Color? color,
      }) {
    return TextStyle(
        fontSize: baseSize / MediaQuery.of(context).textScaleFactor,
        fontWeight: bold ? FontWeight.bold : null,
        color: color);
  }
}
