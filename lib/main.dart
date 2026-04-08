import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_dashboard.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (AppConfig.isCloudReady) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint("SUPABASE INIT FAILED: FALLING BACK TO LOCAL MODE. Error: $e");
      // Optionally toggle a global flag or show a non-fatal warning
    }
  }
  
  runApp(const ExecutionOSApp());
}

class ExecutionOSApp extends StatelessWidget {
  const ExecutionOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Execution OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF39FF14),
          secondary: Color(0xFFFF003C),
          surface: Color(0xFF1A1A1A),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          bodyLarge: GoogleFonts.inter(color: Colors.white70),
        ),
        appBarTheme: const AppBarTheme(
          color: Color(0xFF0F0F0F),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomeDashboard(),
    );
  }
}
