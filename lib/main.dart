import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/food_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

void main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // 한국어 날짜 형식 초기화
  await initializeDateFormatting('ko_KR', null);
  
  // 알림 서비스 초기화
  await NotificationService.instance.initialize();
  
  // 데이터베이스 초기화
  await DatabaseService.instance.database;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 설정 Provider
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        
        // 식품 Provider
        ChangeNotifierProvider(
          create: (_) => FoodProvider(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            
            // 테마 설정
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            
            // 한국어 설정
            locale: const Locale('ko', 'KR'),
            supportedLocales: const [
              Locale('ko', 'KR'),
              Locale('en', 'US'),
            ],
            
            // 홈 화면
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
