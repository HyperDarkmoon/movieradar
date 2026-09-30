import 'package:flutter/material.dart';
import 'package:movieradar/screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:movieradar/providers/theme_provider.dart';
import 'package:movieradar/services/movie_service.dart';
import 'package:movieradar/theme/cinematic_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final movieService = MovieService();
  await movieService.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        if (!themeProvider.isInitialized) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: CinematicTheme.dark(),
            darkTheme: CinematicTheme.dark(),
            themeMode: ThemeMode.dark,
            home: const _SplashScreen(),
          );
        }

        return MaterialApp(
          title: 'MovieRadar',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: CinematicTheme.light(),
          darkTheme: CinematicTheme.dark(),
          home: const MainScreen(),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cinematic.bgTop,
      body: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => Cinematic.glowGradient.createShader(bounds),
          child: const Text(
            'MOVIERADAR',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}