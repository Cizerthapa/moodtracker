import 'package:flutter/material.dart';
import 'screens/entry_screen.dart';

void main() {
  runApp(const MoodTrackApp());
}

class MoodTrackApp extends StatelessWidget {
  const MoodTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodTrack & Memories',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0E),
        primaryColor: const Color(0xFF9E77ED),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9E77ED),
          secondary: Color(0xFFF97066),
          surface: Color(0xFF161622),
          background: Color(0xFF0A0A0E),
        ),
        fontFamily: 'Inter', // Default fallback, but will look good
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        useMaterial3: true,
      ),
      home: const EntryScreen(),
    );
  }
}
