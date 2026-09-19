import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/business_environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (BusinessEnvironment.isConfigured) {
    await Supabase.initialize(
      url: BusinessEnvironment.supabaseUrl,
      publishableKey: BusinessEnvironment.publishableKey,
    );
  }

  runApp(const ProviderScope(child: ManasaknaBusinessApp()));
}
