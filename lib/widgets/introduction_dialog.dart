import 'package:flutter/material.dart';

class IntroductionDialog extends StatelessWidget {
  const IntroductionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('スマート家計簿へようこそ！'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('このアプリの使い方をご紹介します。'),
            SizedBox(height: 20),
            _IntroductionStep(
              icon: Icons.person_outline,
              title: '1. ユーザー名を入力',
              description: '右上にユーザー名を英語で入力してください。',
            ),
            SizedBox(height: 16),
            _IntroductionStep(
              icon: Icons.edit_note,
              title: '2. 支出を登録',
              description: '金額と用途を入力して、「登録」を押してください。',
            ),
            SizedBox(height: 16),
            _IntroductionStep(
              icon: Icons.bar_chart,
              title: '3. グラフを見る',
              description: '「グラフを見る」から登録した支出を確認できます。',
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('はじめる'),
        ),
      ],
    );
  }
}

class _IntroductionStep extends StatelessWidget {
  const _IntroductionStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(description),
            ],
          ),
        ),
      ],
    );
  }
}
