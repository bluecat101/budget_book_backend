import 'package:budget_book/screens/expense_chart_screen.dart';
import 'package:budget_book/screens/expense_entry_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 現在選択されているタブ（'register' または 'graph'）
  String _selectedTab = 'register';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スマート家計簿'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. 登録 / グラフ の切り替えタブ ---
              Center(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'register',
                      label: Text('収支を登録'),
                      icon: Icon(Icons.edit_note),
                    ),
                    ButtonSegment<String>(
                      value: 'graph',
                      label: Text('グラフを見る'),
                      icon: Icon(Icons.bar_chart),
                    ),
                  ],
                  selected: {_selectedTab},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedTab = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. 選択タブに応じた画面の表示 ---
              if (_selectedTab == 'register') ...[
                const Text(
                  '新しい収支の記録',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const ExpenseFormSnippet(),
              ] else ...[
                const ExpenseChartScreen(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
