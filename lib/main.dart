import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/hotel_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/vault_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/extra_services_provider.dart';
import 'providers/activity_log_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/message_provider.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';

void main() {
  // تهيئة قاعدة البيانات لأنظمة Desktop (Windows)
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ActivityLogProvider>(
          create: (_) => ActivityLogProvider(),
          update:
              (_, auth, previous) => ActivityLogProvider(authProvider: auth),
        ),
        ChangeNotifierProxyProvider<ActivityLogProvider, HotelProvider>(
          create: (_) => HotelProvider(),
          update: (_, logs, previous) => HotelProvider(logProvider: logs),
        ),
        ChangeNotifierProxyProvider2<ActivityLogProvider, HotelProvider,
          BookingProvider>(
          create: (_) => BookingProvider(),
          update:
              (_, logs, hotels, previous) =>
                  BookingProvider(logProvider: logs, hotelProvider: hotels),
        ),
        ChangeNotifierProxyProvider<ActivityLogProvider, VaultProvider>(
          create: (_) => VaultProvider(),
          update: (_, logs, previous) {
            if (previous != null) {
              previous.update(logs);
              return previous;
            }
            return VaultProvider(logProvider: logs);
          },
        ),
        ChangeNotifierProvider(create: (_) => SystemSettingsProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProxyProvider<ActivityLogProvider, ExtraServicesProvider>(
          create: (_) => ExtraServicesProvider(),
          update:
              (_, logs, previous) => ExtraServicesProvider(logProvider: logs),
        ),
        ChangeNotifierProxyProvider<BookingProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update:
              (_, booking, previous) =>
                  NotificationProvider(bookingProvider: booking),
        ),
        ChangeNotifierProxyProvider<SystemSettingsProvider, MessageProvider>(
          create: (_) => MessageProvider(),
          update:
              (_, settings, previous) =>
                  MessageProvider(settingsProvider: settings),
        ),
      ],
      child: const HotelCashierApp(),
    ),
  );
}

class HotelCashierApp extends StatelessWidget {
  const HotelCashierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام حجز الفنادق',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E5BB8),
          primary: const Color(0xFF1E5BB8),
          secondary: const Color(0xFF2ECC71),
          brightness: Brightness.light,
        ),
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1E5BB8),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.currentUser != null) {
            return const MainLayout();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
