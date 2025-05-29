import 'package:flutter/material.dart';
import 'screens/main_screen.dart'; // Import the new main screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rick & Morty Tinder',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.pink, // Tinder-like color
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto', // A common, clean font
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFE5048), // Tinder red-pink
          secondary: Color(0xFFE94057), // A slightly different shade
          surface: Color.fromARGB(255, 22, 22, 22), // Dark card surfaces
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onError: Colors.white,
          background: Colors.black,
          onBackground: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          headlineSmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white54),
          titleTextStyle: TextStyle(
            color: Color(0xFFFE5048),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          color: const Color.fromARGB(255, 30, 30, 30), // Darker cards
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
        buttonTheme: ButtonThemeData(
          buttonColor: const Color(0xFFFE5048),
          textTheme: ButtonTextTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        // Add other theme properties as needed
      ),
      home: const MainScreen(), // Set MainScreen as the home
      debugShowCheckedModeBanner: false,
    );
  }
}
