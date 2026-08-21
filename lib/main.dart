import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'config/routes.dart';
import 'core/services/storage_service.dart';
import 'core/services/hive_storage_service.dart';
import 'core/services/inactivity_service.dart';
import 'core/services/notification_push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.getInstance();
  await HiveStorageService.init();
  await NotificationPushService.initialize();
  runApp(const PasseVoyageApp());
}

class PasseVoyageApp extends StatefulWidget {
  const PasseVoyageApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<PasseVoyageApp> createState() => _PasseVoyageAppState();
}

class _PasseVoyageAppState extends State<PasseVoyageApp> {
  @override
  void initState() {
    super.initState();
    InactivityService().init(PasseVoyageApp.navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Listener(
          onPointerDown: (_) => InactivityService().userActivityDetected(),
          onPointerMove: (_) => InactivityService().userActivityDetected(),
          child: MaterialApp(
            navigatorKey: PasseVoyageApp.navigatorKey,
            title: 'Passe Voyage',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            initialRoute: '/',
            onGenerateRoute: AppRoutes.generateRoute,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', 'FR'),
            ],
          ),
        );
      },
    );
  }
}
