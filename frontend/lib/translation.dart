import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppTranslations {
  static Map<String, Map<String, String>> values = {
    'ja': {},
    'en': {},
  };

  // 外部JSONからデータを読み込む関数
  static Future<void> init() async {
    // 日本語のロード
    try {
      
      print('日本語の翻訳データをロード中...');
      String jaJson = await rootBundle.loadString('lang/jp.json');
      values['ja'] = Map<String, String>.from(json.decode(jaJson));
      print('日本語の翻訳データのロード完了');
      
    } catch (e) {
      
      print('エラー: $e');
      
    }

    // 英語のロード
    try {
      
      print('英語の翻訳データをロード中...');
      String enJson = await rootBundle.loadString('lang/en.json');
      values['en'] = Map<String, String>.from(json.decode(enJson));
      print('英語の翻訳データのロード完了');
      
    } catch (e) {
      
      print('エラー: $e');
      
    }
  }

  static final List<Map<String, String>> languages = [
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
  ];
}