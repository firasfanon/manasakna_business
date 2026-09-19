class BusinessEnvironment {
  const BusinessEnvironment._();

  static const productNameAr = 'مناسكنا للأعمال';
  static const productNameEn = 'Manasakna Business';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && publishableKey.trim().isNotEmpty;

  static const phaseLabel = 'Phase 6 — Commercial Umrah SaaS Foundation';
}
