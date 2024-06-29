class SupabaseOptions {
  final String url;
  final String anonKey;

  SupabaseOptions({
    required this.url,
    required this.anonKey,
  });
}

final SupabaseOptions supabaseOptions = SupabaseOptions(
  url: 'https://tnxglgjtuhrxxokpxphr.supabase.co',
  anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRueGdsZ2p0dWhyeHhva3B4cGhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTg3NzUxMjMsImV4cCI6MjAzNDM1MTEyM30.nX6nB4TFhcmXK6tEgCa6PYCcljvImLMp9RfhM0Hl8OE',
);
