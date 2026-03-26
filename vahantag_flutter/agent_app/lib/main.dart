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
  runApp(const AgentApp());
}

class AgentApp extends StatelessWidget {
  const AgentApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AgentAuthProvider()..initialize(),
      child: Consumer<AgentAuthProvider>(
        builder: (_, auth, __) {
          if (auth.isLoading) return const MaterialApp(home: Scaffold(backgroundColor: Color(0xFF0F172A), body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))));
          final router = GoRouter(initialLocation: auth.isAuthenticated ? '/dashboard' : '/login', routes: agentRouter.configuration.routes);
          return MaterialApp.router(
            title: 'VahanTag Agent',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B00)), useMaterial3: true),
            routerConfig: agentRouter,
          );
        },
      ),
    );
  }
}
