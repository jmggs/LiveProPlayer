import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/player_provider.dart';
import 'screens/main_screen.dart';
import 'app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait on phones; allow all orientations on tablets
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Dark status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:            Colors.transparent,
    statusBarBrightness:       Brightness.dark,
    statusBarIconBrightness:   Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => PlayerProvider(),
      child:  const LiveProPlayerApp(),
    ),
  );
}

class LiveProPlayerApp extends StatelessWidget {
  const LiveProPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                  'Live Pro Player',
      theme:                  AppTheme.darkTheme,
      home:                   const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
