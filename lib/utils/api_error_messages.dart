class ApiErrorMessages {
  static const Map<String, String> messages = {
    'NO_USER_NAME': 'ユーザー名を入力してください。',
    'INVALID_PRICE': '金額は0より大きい数値を入力してください。',
    'NO_ITEM': '用途が選択・入力されていません。',
    'USER_NOT_FOUND': 'ユーザーが見つかりません。',
    'INTERNAL_ERROR': '予期しないエラーが発生しました。',
  };

  static String getMessage(String? code) {
    return messages[code] ?? 'エラーが発生しました。時間をおいて再度お試しください。';
  }
}
