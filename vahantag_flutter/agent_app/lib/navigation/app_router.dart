import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/sales/screens/record_sale_screen.dart';
import '../features/inventory/screens/inventory_screen.dart';

final agentRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const AgentLoginScreen()),
    GoRoute(path: '/otp', builder: (_, state) => AgentOTPScreen(phone: (state.extra as Map)['phone'])),
    GoRoute(path: '/pending', builder: (_, __) => const _PendingScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const AgentDashboard()),
    GoRoute(path: '/record-sale', builder: (_, __) => const RecordSaleScreen()),
    GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
    GoRoute(path: '/sales-history', builder: (_, __) => const InventoryScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const _ProfilePlaceholder()),
  ],
);

import 'package:flutter/material.dart';

class _PendingScreen extends StatelessWidget {
  const _PendingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF0F172A),
    body: Center(child: Padding(padding: EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('⏳', style: TextStyle(fontSize: 64)),
      SizedBox(height: 16),
      Text('Approval Pending', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
      SizedBox(height: 8),
      Text('Your agent account is pending admin approval. You will receive an SMS once approved.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.5)),
    ]))),
  );
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F172A),
    appBar: AppBar(backgroundColor: const Color(0xFF1E293B), title: const Text('Profile', style: TextStyle(color: Colors.white)), iconTheme: const IconThemeData(color: Color(0xFFFF6B00))),
    body: const Center(child: Text('Profile Screen', style: TextStyle(color: Colors.white))),
  );
}
