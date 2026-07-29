import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import 'core/services/database_service.dart';
import 'core/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/settings_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/products/presentation/home_screen.dart';
import 'features/products/presentation/add_product_screen.dart';
import 'features/products/presentation/product_detail_screen.dart';
import 'features/products/presentation/edit_product_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

// Firebase Web config options used on Windows
const firebaseOptionsWindows = FirebaseOptions(
  apiKey: "AIzaSyCWlunWsDCJ9Um7PqUk0-UHcoay2IIWbTQ",
  appId: "1:786499061593:web:5e9cf77db213b7a396ee48",
  messagingSenderId: "786499061593",
  projectId: "prizma-stok-takip",
  storageBucket: "prizma-stok-takip.firebasestorage.app",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Yatay dondurmeyi engelle (Sadece dikey mod)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Firebase based on Platform
  if (Platform.isWindows) {
    await Firebase.initializeApp(options: firebaseOptionsWindows);
  } else {
    await Firebase.initializeApp();
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Local Isar Database
  final isar = await DatabaseService.init();
  final databaseService = DatabaseService(isar);

  // Initialize SyncService and start monitoring
  final syncService = SyncService(databaseService);
  syncService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(databaseService),
        syncServiceProvider.overrideWithValue(syncService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PrizmaApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/add-product',
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/product-detail/:uuid',
        builder: (context, state) {
          final uuid = state.pathParameters['uuid']!;
          return ProductDetailScreen(productUuid: uuid);
        },
      ),
      GoRoute(
        path: '/edit-product/:uuid',
        builder: (context, state) {
          final uuid = state.pathParameters['uuid']!;
          return EditProductScreen(productUuid: uuid);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

class PrizmaApp extends ConsumerWidget {
  const PrizmaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Prizma',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE),
          brightness: Brightness.light,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE),
          brightness: Brightness.dark,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
