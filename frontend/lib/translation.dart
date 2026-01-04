import 'dart:convert';
import 'package:flutter/services.dart';

class AppTranslations {
  static Map<String, Map<String, String>> values = {
    'ja': {},
    'en': {},
  };

  // 外部JSONからデータを読み込む関数
  static Future<void> init() async {
    // 日本語のロード
    String jaJson = await rootBundle.loadString('lang/jp.json');
    values['ja'] = Map<String, String>.from(json.decode(jaJson));

    // 英語のロード
    String enJson = await rootBundle.loadString('lang/en.json');
    values['en'] = Map<String, String>.from(json.decode(enJson));
  }

  static final List<Map<String, String>> languages = [
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
  ];
}