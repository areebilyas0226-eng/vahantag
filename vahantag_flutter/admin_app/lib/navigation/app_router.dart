import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/users/screens/users_screen.dart';
import '../features/agents/screens/agents_screen.dart';
import '../features/tags/screens/tags_screen.dart';
import '../features/categories/screens/categories_screen.dart';
import '../features/revenue/screens/revenue_screen.dart';

/// Call this with [isAuthenticated] so the app starts on the
/// correct screen — dashboard if already logged in, login otherwise.
GoRouter buildAdminRouter(bool isAuthenticated) {
  return GoRouter(
    initialLocation: isAuthenticated ? '/dashboard' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/users',
        builder: (_, __) => const UsersScreen(),
      ),
      GoRoute(
        path: '/agents',
        builder: (_, __) => const AgentsScreen(),
      ),
      GoRoute(
        path: '/tags',
        builder: (_, __) => const TagsScreen(),
      ),
      GoRoute(
        path: '/generate-tags',
        builder: (_, __) => const TagsScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (_, __) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/revenue',
        builder: (_, __) => const AdminRevenueScreen(),
      ),
    ],
  );
}
