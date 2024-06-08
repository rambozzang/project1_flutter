class SupabaseOptions {
  final String url;
  final String anonKey;

  SupabaseOptions({
    required this.url,
    required this.anonKey,
  });
}

final SupabaseOptions supabaseOptions = SupabaseOptions(
  url: 'https://wtyeuynrapbgtpquxxfm.supabase.co',
  anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0eWV1eW5yYXBiZ3RwcXV4eGZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTc1NTM4NzYsImV4cCI6MjAzMzEyOTg3Nn0.RZKF6Nfkqr7fA7Uc7RtZc_Jnl4zw_Q6iDV-5J9DfIM8',
);
