import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/services/notification_service.dart';
import 'features/main_app/presentation/providers/locale_provider.dart';
import 'features/main_app/presentation/providers/theme_provider.dart';
import 'features/main_app/presentation/providers/timer_provider.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'l10n/app_localizations.dart';


Future<void> main() async {
  // ảm bảo rằng các thành phần của Flutter đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp();

  await NotificationService.initialize();

  // Chạy ứng dụng sau khi đã khởi tạo xong
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          title: 'Taskflow',
          debugShowCheckedModeBanner: false,

          locale: localeProvider.locale, // Lấy ngôn ngữ hiện tại từ provider
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // ==============================

          // === GIAO DIỆN SÁNG (LIGHT THEME) ===
          theme: ThemeData(
            brightness: Brightness.light,
            canvasColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            fontFamily: 'Inter',
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(0xFFE1DFFF)
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFF1E1E1E), fontWeight: FontWeight.w600, fontSize: 24),

              titleMedium: TextStyle(fontFamily: 'Inter', color: Color(0xFF837F7D), fontWeight: FontWeight.w600, fontSize: 16),

              titleLarge: TextStyle(fontFamily: 'Inter', color: Color(0xFF0F0F0F), fontWeight: FontWeight.w600, fontSize: 20),

              bodyLarge: TextStyle(fontFamily: 'Inter', color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16),

              bodyMedium: TextStyle(fontFamily: 'Inter', color: Color(0xFF242424), fontWeight: FontWeight.w400, fontSize: 14),

              labelLarge: TextStyle(fontFamily: 'Inter', color: Color(0xFF837F7D), fontWeight: FontWeight.w600),
            ),
          ),

          // === GIAO DIỆN TỐI (BỔ SUNG THÊM) ===
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            //scaffoldBackgroundColor: const Color(0xFF121212),
            //canvasColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            fontFamily: 'Inter',
            primaryColor: Colors.tealAccent,
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 24),

              titleMedium: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w600),
              titleLarge: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
              bodyLarge: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              bodyMedium: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14),
              labelLarge: TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),

          // Quyết định dùng theme nào dựa trên provider
          themeMode: themeProvider.themeMode,

          home: const SplashScreen(),
        );
      },
    );
  }
}