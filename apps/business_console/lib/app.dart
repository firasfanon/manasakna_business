import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/business_environment.dart';
import 'core/auth/login_page.dart';
import 'features/dashboard/presentation/dashboard_page.dart';
import 'features/tenancy/presentation/tenant_session.dart';

class ManasaknaBusinessApp extends ConsumerWidget {
  const ManasaknaBusinessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: BusinessEnvironment.productNameAr,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B6B56)),
        useMaterial3: true,
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: BusinessEnvironment.isConfigured
          ? const _AuthGate()
          : const _ConfigurationRequiredPage(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (client.auth.currentSession == null) {
          return const BusinessLoginPage();
        }

        final contextState = ref.watch(businessContextProvider);
        return contextState.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'فشل تحميل سياق الشركة بصورة آمنة:\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          data: (contextEnvelope) =>
              BusinessDashboardPage(contextEnvelope: contextEnvelope),
        );
      },
    );
  }
}

class _ConfigurationRequiredPage extends StatelessWidget {
  const _ConfigurationRequiredPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'مناسكنا للأعمال يعمل Fail-Closed.\n'
            'لم يتم ربط مشروع Supabase تجاري بعد.\n'
            'Phase 6 لا يستخدم بيانات حقيقية أو صلاحيات حج سيادية.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
