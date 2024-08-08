import 'dart:io';

import 'package:easy_wallet/views/main/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'generated/l10n.dart';

void main() {
  runApp(const EasyWalletApp());
}

class EasyWalletApp extends StatefulWidget {
  const EasyWalletApp({super.key});

  @override
  EasyWalletAppState createState() => EasyWalletAppState();

  static TextStyle responsiveTextStyle(
      double baseSize,
      BuildContext context, {
        bool bold = false,
        Color? color,
      }) {
    return TextStyle(
      fontSize: baseSize / MediaQuery.of(context).textScaleFactor,
      fontWeight: bold ? FontWeight.bold : null,
      color: color,
    );
  }
}

class EasyWalletAppState extends State<EasyWalletApp> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _shouldAuthenticate = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authenticateOnStartup();
  }

  Future<void> _authenticateOnStartup() async {
    bool shouldAuthenticate = await checkAuthenticationSetting();
    if (shouldAuthenticate) {
      bool isAuthenticated = await authenticateWithBiometrics();
      if (!isAuthenticated) {
        exit(0);
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && _shouldAuthenticate && !_isAuthenticating) {
      _shouldAuthenticate = false;
      _isAuthenticating = true;
      setState(() {
        _isLoading = true;
      });
      bool shouldAuthenticate = await checkAuthenticationSetting();
      if (shouldAuthenticate) {
        bool isAuthenticated = await authenticateWithBiometrics();
        _isAuthenticating = false;
        if (!isAuthenticated) {
          exit(0);
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _isAuthenticating = false;
        setState(() {
          _isLoading = false;
        });
      }
    }
    if (state == AppLifecycleState.paused) {
      setState(() {
        _shouldAuthenticate = true;
      });
    }
  }

  Future<bool> checkAuthenticationSetting() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('require_authentication') ?? false;
  }

  Future<bool> authenticateWithBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool canAuthenticate = false;

    try {
      canAuthenticate =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }

    if (!canAuthenticate) {
      return false;
    }

    try {
      final List<BiometricType> availableBiometrics =
      await auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return false;
      }

      if (!availableBiometrics.contains(BiometricType.face)) {
        return false;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
        Intl.message('pleaseAuthenticateYourselfToViewYourSubscriptions'),
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException {
      return false;
    }
  }

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
      home: _isLoading ? const SplashScreen() : const MainView(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }
}
