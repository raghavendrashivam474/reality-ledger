class AppConfig {
  // CONFIGURATION HUB: PASTE YOUR SUPABASE CREDENTIALS HERE
  static const String supabaseUrl = ''; // ENTER_YOUR_URL
  static const String supabaseAnonKey = ''; // ENTER_YOUR_ANON_KEY

  static bool get isCloudReady => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  
  // Brutality Level: Set to true for more aggressive feedback
  static const bool intenseMode = true;
}
