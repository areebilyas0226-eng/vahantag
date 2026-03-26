import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/assets/screens/assets_screen.dart';
import '../features/assets/screens/add_asset_screen.dart';
import '../features/tag/screens/activate_tag_screen.dart';
import '../features/emergency/screens/emergency_page_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class AppRouter {
  static GoRouter router(BuildContext context) => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/otp', builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return OTPScreen(phone: extra['phone']);
      }),
      ShellRoute(
        builder: (_, __, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/assets', builder: (_, __) => const AssetsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(path: '/add-asset', builder: (_, __) => const AddAssetScreen()),
      GoRoute(path: '/activate-tag', builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ActivateTagScreen(assetId: extra?['assetId'], assetName: extra?['assetName']);
      }),
      GoRoute(path: '/e/:tagCode', builder: (_, state) => EmergencyPageScreen(tagCode: state.pathParameters['tagCode']!)),
    ],
  );
}

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final _tabs = ['/home', '/assets', '/profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFF5EE),
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          context.go(_tabs[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFFFF6B00)), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2, color: Color(0xFFFF6B00)), label: 'Assets'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Color(0xFFFF6B00)), label: 'Profile'),
        ],
      ),
    );
  }
}
