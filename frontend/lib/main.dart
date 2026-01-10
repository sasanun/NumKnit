import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle; // rootBundleを追加
import 'package:yaml/yaml.dart'; // YAMLパーサー
import 'package:url_launcher/url_launcher.dart'; // URL起動用

import 'package:frontend/translation.dart';
import 'package:frontend/adProduct.dart';

class AppColors {
  // ブランドカラー
  static const Color primary = Colors.teal;
  static final Color primaryLight = Colors.teal.shade100;
  static final Color primaryDark = Colors.teal.shade800;
  
  // ボーダー
  static final Color border = Colors.grey.shade300;
  
  // 機能色
  static const Color pdf = Color(0xFFD32F2F);
  static const Color excel = Color(0xFF388E3C);

  // ヘルパーテキスト色
  static final Color helperText = Colors.grey.shade500;
  
}

void main() async {
  if (kDebugMode) {
    print('デバッグ中');
  }

  // Flutterのバインディングを初期化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 翻訳データをロード
  if (kDebugMode) {
    print('翻訳データを初期化中...');
  }
  await AppTranslations.init();
  
  runApp(const KnittingApp());
}

class KnittingApp extends StatefulWidget {
  const KnittingApp({super.key});

  @override
  State<KnittingApp> createState() => _KnittingAppState();
}

class _KnittingAppState extends State<KnittingApp> {
  String _locale = 'ja';

  String t(String key) => AppTranslations.values[_locale]?[key] ?? key;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        brightness: Brightness.light,
      ),
      home: SweaterInputPage(
        t: t,
        onLocaleChange: (val) => setState(() => _locale = val!),
        currentLocale: _locale,
      ),
    );
  }
}

class SweaterInputPage extends StatefulWidget {
  final String Function(String) t;
  final Function(String?) onLocaleChange;
  final String currentLocale;

  const SweaterInputPage({super.key, required this.t, required this.onLocaleChange, required this.currentLocale});

  @override
  State<SweaterInputPage> createState() => _SweaterInputPageState();
}

class _SweaterInputPageState extends State<SweaterInputPage> {
  final Map<String, TextEditingController> _controllers = {
    'length_of_body': TextEditingController(),
    'length_of_shoulder_drop': TextEditingController(),
    'length_of_ribbed_hem': TextEditingController(),
    'length_of_front_neck_drop': TextEditingController(),
    'length_of_back_neck_drop': TextEditingController(),
    'width_of_body': TextEditingController(),
    'width_of_neck': TextEditingController(),
    'length_of_sleeve': TextEditingController(),
    'length_of_ribbed_cuff': TextEditingController(),
    'width_of_sleeve': TextEditingController(),
    'width_of_cuff': TextEditingController(),
    'sts_10cm': TextEditingController(),
    'rows_10cm': TextEditingController(),
  };

  String _unit = 'CM';
  String _sweaterType = 'Crew';
  String? _selectedSize; // 現在選択されているサイズ

  // 広告スライド用の状態
  late PageController _adPageController;
  late Timer _adSlideTimer;
  int _currentAdPageIndex = 0;
  List<List<AdProduct>> _adProductSets = []; // 広告商品の3つのセット

  @override
  void initState() {
    super.initState();
    _adPageController = PageController();
    _loadAdProducts(); // アプリ起動時に広告商品を読み込む
  }

  @override
  void dispose() {
    _adSlideTimer.cancel(); // タイマーのキャンセルを忘れない
    _adPageController.dispose(); // PageControllerの破棄を忘れない
    super.dispose();
  }

  // URLを外部ブラウザで開く
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // エラーメッセージを表示するなど
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  // 標準サイズデータ（CM単位の想定）
  final Map<String, Map<String, String>> _sizeDefaults = {
    'Men L': {'width_of_body': '58', 'length_of_body': '70', 'width_of_neck': '20', 'length_of_sleeve': '62', 'width_of_sleeve': '25', 'length_of_ribbed_hem': '6', 'length_of_shoulder_drop': '3', 'length_of_front_neck_drop': '9', 'length_of_back_neck_drop': '2', 'width_of_cuff': '10', 'length_of_ribbed_cuff': '6'},
    'Men M': {'width_of_body': '54', 'length_of_body': '66', 'width_of_neck': '19', 'length_of_sleeve': '60', 'width_of_sleeve': '23', 'length_of_ribbed_hem': '6', 'length_of_shoulder_drop': '2.5', 'length_of_front_neck_drop': '8.5', 'length_of_back_neck_drop': '2', 'width_of_cuff': '9.5', 'length_of_ribbed_cuff': '6'},
    'Men S': {'width_of_body': '50', 'length_of_body': '62', 'width_of_neck': '18', 'length_of_sleeve': '58', 'width_of_sleeve': '21', 'length_of_ribbed_hem': '5', 'length_of_shoulder_drop': '2', 'length_of_front_neck_drop': '8', 'length_of_back_neck_drop': '2', 'width_of_cuff': '9', 'length_of_ribbed_cuff': '5'},
    'LADY L': {'width_of_body': '52', 'length_of_body': '60', 'width_of_neck': '19', 'length_of_sleeve': '56', 'width_of_sleeve': '20', 'length_of_ribbed_hem': '5', 'length_of_shoulder_drop': '2.5', 'length_of_front_neck_drop': '8.5', 'length_of_back_neck_drop': '2', 'width_of_cuff': '9', 'length_of_ribbed_cuff': '5'},
    'LADY M': {'width_of_body': '49', 'length_of_body': '58', 'width_of_neck': '18', 'length_of_sleeve': '54', 'width_of_sleeve': '19', 'length_of_ribbed_hem': '5', 'length_of_shoulder_drop': '2', 'length_of_front_neck_drop': '8', 'length_of_back_neck_drop': '2', 'width_of_cuff': '8.5', 'length_of_ribbed_cuff': '5'},
    'LADY S': {'width_of_body': '46', 'length_of_body': '56', 'width_of_neck': '17', 'length_of_sleeve': '52', 'width_of_sleeve': '18', 'length_of_ribbed_hem': '4', 'length_of_shoulder_drop': '1.5', 'length_of_front_neck_drop': '7.5', 'length_of_back_neck_drop': '1.5', 'width_of_cuff': '8', 'length_of_ribbed_cuff': '4'},
    'KIDs L': {'width_of_body': '42', 'length_of_body': '50', 'width_of_neck': '16', 'length_of_sleeve': '45', 'width_of_sleeve': '17', 'length_of_ribbed_hem': '4', 'length_of_shoulder_drop': '1.5', 'length_of_front_neck_drop': '7', 'length_of_back_neck_drop': '1.5', 'width_of_cuff': '8', 'length_of_ribbed_cuff': '4'},
    'KIDs M': {'width_of_body': '38', 'length_of_body': '45', 'width_of_neck': '15', 'length_of_sleeve': '40', 'width_of_sleeve': '15', 'length_of_ribbed_hem': '3', 'length_of_shoulder_drop': '1', 'length_of_front_neck_drop': '6.5', 'length_of_back_neck_drop': '1', 'width_of_cuff': '7.5', 'length_of_ribbed_cuff': '3'},
    'KIDs S': {'width_of_body': '34', 'length_of_body': '40', 'width_of_neck': '14', 'length_of_sleeve': '35', 'width_of_sleeve': '14', 'length_of_ribbed_hem': '3', 'length_of_shoulder_drop': '1', 'length_of_front_neck_drop': '6', 'length_of_back_neck_drop': '1', 'width_of_cuff': '7', 'length_of_ribbed_cuff': '3'},
  };

  // サイズを選択した時の処理
  void _applySize(String sizeKey) {
    setState(() {
      _selectedSize = sizeKey;
      final defaults = _sizeDefaults[sizeKey];
      if (defaults != null) {
        defaults.forEach((key, value) {
          if (_controllers.containsKey(key)) {
            _controllers[key]!.text = value;
          }
        });
      }
    });
  }

  final List<Map<String, String>> _sweaterTypes = [
    {'id': 'Crew', 'label': 'crew', 'image': 'https://via.placeholder.com/100?text=Crew'},
    {'id': 'V-Neck', 'label': 'v_neck', 'image': 'https://via.placeholder.com/100?text=V-Neck'},
    {'id': 'High', 'label': 'high', 'image': 'https://via.placeholder.com/100?text=High'},
    {'id': 'Cardigan', 'label': 'cardigan', 'image': 'https://via.placeholder.com/100?text=Cardigan'},
    {'id': 'Raglan', 'label': 'raglan', 'image': 'https://via.placeholder.com/100?text=Raglan'},
    {'id': 'Boat', 'label': 'boat', 'image': 'https://via.placeholder.com/100?text=Boat'},
    {'id': 'Turtle', 'label': 'turtle', 'image': 'https://via.placeholder.com/100?text=Turtle'},
    {'id': 'Open', 'label': 'open', 'image': 'https://via.placeholder.com/100?text=Open'},
  ];

  final List<Map<String, dynamic>> _formats = [
    {'id': 'PDF', 'label': 'PDF Document', 'icon': Icons.picture_as_pdf, 'color': AppColors.pdf},
    {'id': 'Excel', 'label': 'Excel Sheet', 'icon': Icons.table_chart, 'color': AppColors.excel},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.t('title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              if (value == 'language_settings') {
                _showLanguageDialog(); // ダイアログを開く
              }
              // 他の拡張機能（ログインなど）
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'language_settings',
                child: Row(
                  children: [
                    Icon(Icons.translate, size: 20),
                    SizedBox(width: 12),
                    Text('Language / 言語'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'account',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Login / Account'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 850 ? 2 : 1;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  children: [
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        mainAxisExtent: 350, // 画像(200) + 余白を考慮して少し広めに
                      ),
                      children: [
                        _buildGaugeCard(), // ゲージカード
                        _buildTypeCard(), // タイプカード
                        _buildSizeCard(), // サイズカード
                        _buildBodyCard(), // 身頃カード
                        _buildNeckShoulderCard(), // 首・肩カード
                        _buildSleeveCard(), // 袖カード
                        _buildAdCard(), // 広告カード
                        _buildDownloadCard(), // ダウンロードカード
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI Components ---

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final languages = AppTranslations.languages;

        return AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true, // 内容に合わせて高さを調整
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                final isSelected = widget.currentLocale == lang['code'];
                
                return ListTile(
                  leading: Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                  title: Text(lang['name']!),
                  trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    widget.onLocaleChange(lang['code']);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGaugeCard() {
    // ここでは「翻訳キー」を選択する
    final String stsKey = _unit == 'CM' ? 'sts_10cm' : 'sts_4inch';
    final String rowsKey = _unit == 'CM' ? 'rows_10cm' : 'rows_4inch';

    return _buildImageInputCard(
      'gauge', 
      Icons.grid_on, 
      [
        SegmentedButton<String>(
          showSelectedIcon: false,
          // 全体のスタイルを調整して余白を固定
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.comfortable,
            padding: EdgeInsets.zero,
          ),
          segments: [
            ButtonSegment(
              value: 'CM', 
              label: SizedBox(
                width: 60, // ここで幅を固定！
                child: Center(child: Text('Cm', style: TextStyle(fontSize: 12))),
              ),
            ),
            ButtonSegment(
              value: 'INCH', 
              label: SizedBox(
                width: 60, // 同じ幅に合わせる
                child: Center(child: Text('Inch', style: TextStyle(fontSize: 12))),
              ),
            ),
          ],
          selected: {_unit},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() => _unit = newSelection.first);
          },
        ),
        const SizedBox(height: 16),
        // _numFieldの中で widget.t() を使って翻訳を適用する
        _numField(widget.t(stsKey), _controllers['sts_10cm'], icon: Icons.height, quarterTurns: 1),
        _numField(widget.t(rowsKey), _controllers['rows_10cm'], icon: Icons.height),
      ],
    );
  }

  Widget _buildTypeCard() {
    return _baseCard(
      title: widget.t('type'),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: _sweaterTypes.length,
        itemBuilder: (context, index) {
          final type = _sweaterTypes[index];
          final isSelected = _sweaterType == type['id'];
          return InkWell(
            onTap: () => setState(() => _sweaterType = type['id']!),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 3 : 1),
                color: isSelected ? AppColors.primaryLight : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(type['image']!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.checkroom)),
                      ),
                    ),
                  ),
                  Text(
                    widget.t(type['label']!), // ここで翻訳を通す
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSizeCard() {
    // カテゴリごとのリスト
    final List<String> menSizes = ['Men S', 'Men M', 'Men L'];
    final List<String> ladySizes = ['LADY S', 'LADY M', 'LADY L'];
    final List<String> kidsSizes = ['KIDs S', 'KIDs M', 'KIDs L'];

    return _baseCard(
      title: 'Standard Size',
      child: Column(
        children: [
          // 1列目（1行目）：カスタムボタンのみ
          _buildSizeRow(['Custom'], isCustomRow: true),
          const Divider(height: 16), // 少し区切りを入れる
          // 2列目以降：各サイズ
          Expanded(child: _buildSizeRow(menSizes)),
          Expanded(child: _buildSizeRow(ladySizes)),
          Expanded(child: _buildSizeRow(kidsSizes)),
        ],
      ),
    );
  }

  // ボタンの行を作成するヘルパー
  // ボタンの行を作成するヘルパー
  Widget _buildSizeRow(List<String> sizes, {bool isCustomRow = false}) {
    // 型を Widget に統一するためのリスト作成
    List<Widget> rowChildren = sizes.map<Widget>((size) {
      final isSelected = _selectedSize == size;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: isSelected ? AppColors.primaryLight : null,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() => _selectedSize = size);
              if (!isCustomRow) {
                _applySize(size);
              }
            },
            child: Text(
              size.replaceAll(' ', '\n'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
          ),
        ),
      );
    }).toList();

    // カスタム行の場合、残り2つ分を空けてバランスを取る
    if (isCustomRow) {
      rowChildren.add(const Spacer());
      rowChildren.add(const Spacer());
    }

    return Row(children: rowChildren);
  }

  // 身頃カード
  Widget _buildBodyCard() => _buildImageInputCard('body', Icons.straighten, [
        _numField(widget.t('width_of_body'), _controllers['width_of_body'], icon: Icons.height, quarterTurns: 1, suffix: _unit),
        _numField(widget.t('length_of_body'), _controllers['length_of_body'], icon: Icons.height, suffix: _unit),
        _numField(widget.t('length_of_ribbed_hem'), _controllers['length_of_ribbed_hem'], icon: Icons.height, suffix: _unit),
      ]);

  // 襟と肩カード
  Widget _buildNeckShoulderCard() => _buildImageInputCard('neck_shoulder', Icons.architecture, [
        _numField(widget.t('width_of_neck'), _controllers['width_of_neck'], icon: Icons.height, quarterTurns: 1, suffix: _unit),
        _numField(widget.t('length_of_shoulder_drop'), _controllers['length_of_shoulder_drop'], icon: Icons.height, suffix: _unit),
        _numField(widget.t('length_of_front_neck_drop'), _controllers['length_of_front_neck_drop'], icon: Icons.height, suffix: _unit),
        _numField(widget.t('length_of_back_neck_drop'), _controllers['length_of_back_neck_drop'], icon: Icons.height, suffix: _unit),
      ]);

  // 袖カード
  Widget _buildSleeveCard() => _buildImageInputCard('sleeve', Icons.edit, [
        _numField(widget.t('length_of_sleeve'), _controllers['length_of_sleeve'], icon: Icons.height, suffix: _unit),
        _numField(widget.t('width_of_sleeve'), _controllers['width_of_sleeve'], icon: Icons.height, quarterTurns: 1, suffix: _unit),
        _numField(widget.t('width_of_cuff'), _controllers['width_of_cuff'], icon: Icons.height, quarterTurns: 1, suffix: _unit),
        _numField(widget.t('length_of_ribbed_cuff'), _controllers['length_of_ribbed_cuff'], icon: Icons.height, suffix: _unit),
      ]);

  // 画像と入力を並べるための共通ビルダー
  Widget _buildImageInputCard(String titleKey, IconData icon, List<Widget> fields) {
    return _baseCard(
      title: widget.t(titleKey),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140, // 200だと狭い画面で入力欄が圧迫されるため少し調整
            height: 140,
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.grey, size: 48),
          ),
          const SizedBox(width: 16),
          Expanded(child: SingleChildScrollView(child: Column(children: fields))),
        ],
      ),
    );
  }

  // 広告掲載用カード
  // YAMLファイルから広告商品を読み込み、セットに分割する関数
  Future<void> _loadAdProducts() async {
    try {
      print("YAML読み込み開始..."); // ←確認用
      final String yamlString = await rootBundle.loadString('data/products.yaml');
      print("ファイル取得成功"); // ←ここまで来なければパス間違い

      final dynamic yamlData = loadYaml(yamlString);
      print("YAMLパース成功: $yamlData");
      if (yamlData is YamlList) {
      List<AdProduct> allProducts = yamlData.map((item) {
        // ここがポイント：YamlMap を Map<String, dynamic> に安全に変換する
        final map = item as Map;
        final convertedMap = map.map((key, value) => MapEntry(key.toString(), value));
        return AdProduct.fromMap(convertedMap);
      }).toList();

      if (allProducts.isEmpty) return;

      // 全商品をシャッフルし、8個ずつ3組に分割
      allProducts.shuffle();
      
      List<List<AdProduct>> tempSets = [];
      for (int i = 0; i < 3; i++) {
        // リストが足りない場合の範囲外エラーを防ぐ
        int start = i * 8;
        if (start < allProducts.length) {
          int end = (start + 8 > allProducts.length) ? allProducts.length : start + 8;
          tempSets.add(allProducts.sublist(start, end));
        }
      }

      setState(() {
        _adProductSets = tempSets;
      });

      _startAdSlideTimer();
    }
  } catch (e) {
    print('YAMLパースエラー: $e');
  }
      
  }

  // 自動スライドタイマー開始
  void _startAdSlideTimer() {
    _adSlideTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_adProductSets.isEmpty || _adProductSets[0].isEmpty || _adProductSets.length <= 1) return; // 商品がない、または1組しかない場合はスライドしない

      int nextPage = (_currentAdPageIndex + 1) % _adProductSets.length;
      _adPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }
  Widget _buildAdCard() {
    // データがまだ読み込まれていないか、空の場合
    if (_adProductSets.isEmpty || _adProductSets[0].isEmpty) {
      return _baseCard(
        title: widget.t('recommended_items'),
        child: const Center(child: CircularProgressIndicator()), // ローディング表示
      );
    }

    return _baseCard(
      title: widget.t('recommended_items'),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PageView.builder(
                  controller: _adPageController,
                  itemCount: _adProductSets.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentAdPageIndex = index; // 現在のページインデックスを更新
                    });
                    _adSlideTimer.cancel(); // 手動でスライドしたらタイマーをリセット
                    _startAdSlideTimer(); // 再度タイマーを開始
                  },
                  itemBuilder: (context, setIndex) {
                    final productsInSet = _adProductSets[setIndex];
                    // productsInSetが8個未満の場合も対応できるようにする
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(), // PageView内なのでスクロールは不要
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 2行4列 = 8個
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.0, // 正方形を維持
                      ),
                      itemCount: productsInSet.length,
                      itemBuilder: (context, productIndex) {
                        final product = productsInSet[productIndex];
                        return _buildAdProductItem(product);
                      },
                    );
                  },
                ),
                // 左スライドボタン
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
                    onPressed: () {
                      _adPageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                  ),
                ),
                // 右スライドボタン
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.black54),
                    onPressed: () {
                      _adPageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ページインジケーター (ドット)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_adProductSets.length, (index) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentAdPageIndex == index
                      ? AppColors.primary // 選択中のドット
                      : Colors.grey, // 未選択のドット
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // 個々の広告商品アイテムのウィジェット
  Widget _buildAdProductItem(AdProduct product) {
    return Tooltip(
      message: product.name, // ホバーで商品タイトル表示
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: () => _launchURL(product.url), // タップでAmazonへ
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7), // Borderより少し小さくして内側に収める
            child: Image.network(
              product.image,
              fit: BoxFit.cover, // 正方形に画像をフィットさせる
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image, size: 30));
              },
            ),
          ),
        ),
      ),
    );
  }

  // ダウンロードカード
  Widget _buildDownloadCard() {
    return _baseCard(
      title: widget.t('download'),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _formats.length,
        itemBuilder: (context, index) {
          final format = _formats[index];
          return InkWell(
            onTap: () => _handleDownload(format['id']),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: (format['color'] as Color).withValues(alpha: 0.1),
                border: Border.all(color: (format['color'] as Color).withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(format['icon'] as IconData, size: 80, color: format['color']), // ドカンと大きく
                  Text(format['id'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: format['color'])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _baseCard({required String title, required Widget child}) {
    return Card(
      elevation: 0.1,
      shape: RoundedRectangleBorder(side: BorderSide(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const Divider(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController? controller, {IconData? icon, int quarterTurns = 0, String? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null 
              ? RotatedBox(
                  quarterTurns: quarterTurns, 
                  child: Icon(icon, size: 20, color: AppColors.primaryDark),
                ) 
              : null,
          // ここに単位を表示 (例: cm / inch)
          suffixText: suffix?.toLowerCase(), 
          suffixStyle: TextStyle(color: AppColors.helperText, fontSize: 12),
          isDense: true,
          border: const UnderlineInputBorder(),
        ),
      ),
    );
  }

  void _handleDownload(String selectedFormat) {
    final Map<String, double> results = {};
    _controllers.forEach((key, controller) => results[key] = double.tryParse(controller.text) ?? 0.0);
    
    // 選択されたフォーマットを使用して処理
    print('API Request ($selectedFormat): $results');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $selectedFormat for ${widget.t(_sweaterType.toLowerCase())}...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      )
    );
  }
}