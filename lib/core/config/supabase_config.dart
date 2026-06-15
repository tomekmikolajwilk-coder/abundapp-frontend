/// Konfiguracja połączenia z Supabase.
///
/// `supabaseUrl` + `supabaseAnonKey` służą do inicjalizacji SDK
/// (`Supabase.initialize`) oraz jako fallback w nagłówkach API, dopóki user nie
/// jest zalogowany. `functionsBaseUrl` to bazowy adres Edge Functions.
const supabaseUrl = 'https://mrcjjyaljautuylpsssp.supabase.co';

const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1yY2pqeWFsamF1dHV5bHBzc3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NjIxNjIsImV4cCI6MjA2NDUzODE2Mn0.9Fv4-e-4ntnxHXHFkRrnqFsqrXeq3VHCWdwKzGQhRLs';

const functionsBaseUrl = '$supabaseUrl/functions/v1';
