import 'package:budget_book/screens/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  // Flutterのウィジェットバインディングを初期化
  WidgetsFlutterBinding.ensureInitialized();

  // .env ファイルを読み込む
  await dotenv.load(fileName: ".env");

  runApp(const BudgetBookApp());
}

class BudgetBookApp extends StatelessWidget {
  const BudgetBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'スマート家計簿',
      locale: const Locale('ja', 'JP'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
