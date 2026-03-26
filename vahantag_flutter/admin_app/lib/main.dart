import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/services/api_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  ApiService().init();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminAuthProvider()..initialize(),
      child: Consumer<AdminAuthProvider>(
        builder: (_, auth, __) {
          // Show splash while checking stored token
          if (auth.isLoading) {
            return const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                backgroundColor: Color(0xFF0F172A),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('⚙️', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 16),
                      Text(
                        'VahanTag Admin',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF6B00),
                        ),
                      ),
                      SizedBox(height: 32),
                      CircularProgressIndicator(color: Color(0xFFFF6B00)),
                    ],
                  ),
                ),
              ),
            );
          }

          return MaterialApp.router(
            title: 'VahanTag Admin',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B00)),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF0F172A),
            ),
            routerConfig: buildAdminRouter(auth.isAuthenticated),
          );
        },
      ),
    );
  }
}
