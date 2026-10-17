import 'package:budget_book/screens/expense_chart_screen.dart';
import 'package:budget_book/screens/expense_entry_screen.dart';
import 'package:budget_book/services/user_preference_service.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _userNameController = TextEditingController();
  String _selectedTab = 'register';

  @override
  void initState() {
    super.initState();
    _loadSavedUser();
  }

  // アプリ起動時に保存されていた直近の名前を読み込む
  Future<void> _loadSavedUser() async {
    final lastUser = await UserPreferenceService.getLastUser();
    setState(() {
      _userNameController.text = lastUser;
    });
  }

  // 名前が変更されたら保存する
  void _onUserChanged(String value) {
    UserPreferenceService.saveLastUser(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スマート家計簿'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // ★ ヘッダーの右上にユーザー入力欄を配置
        actions: [
          SizedBox(
            width: 120, // 少しコンパクトに調整
            child: TextField(
              controller: _userNameController,
              onChanged: _onUserChanged,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                // labelTextの代わりに hintText を使うことで、枠が変形してはみ出るのを防ぎます
                hintText: '名前を入力',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.person, size: 15),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
              ),
            ),
          ),
        ],
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
                ExpenseEntryScreen(userNameController: _userNameController),
              ] else ...[
                ExpenseChartScreen(userNameController: _userNameController),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
