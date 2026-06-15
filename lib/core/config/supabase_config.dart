/// Konfiguracja połączenia z Supabase.
///
/// `supabaseUrl` + `supabaseAnonKey` służą do inicjalizacji SDK
/// (`Supabase.initialize`) oraz jako fallback w nagłówkach API, dopóki user nie
/// jest zalogowany. `functionsBaseUrl` to bazowy adres Edge Functions.
const supabaseUrl = 'https://mrcjjyaljautuylpsssp.supabase.co';

const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1yY2pqeWFsamF1dHV5bHBzc3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4ODE3MTksImV4cCI6MjA5NTQ1NzcxOX0.DDouJha2-LoDVnujUcFUhG9Y8xhJnRPpaDghMWCcsLg';

const functionsBaseUrl = '$supabaseUrl/functions/v1';
