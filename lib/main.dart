
import 'package:flutter/material.dart';
import 'screens/feedback_form.dart';
import 'screens/dashboard.dart';
import "screens/login_screen.dart";

void main() => runApp(const FeedbackApp());

class FeedbackApp extends StatelessWidget {
  const FeedbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classroom Feedback',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xFFF5F7FB),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
      ),
      initialRoute: '/',
     routes: {
  '/': (context) => const FeedbackForm(), // or LoginScreen if you want it first
  '/login': (context) => const LoginScreen(),
  '/dashboard': (context) => const DashboardPage(),
  '/feedback': (context) => const FeedbackForm(),
},
    );
  }
}
//v2
