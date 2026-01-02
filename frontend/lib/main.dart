import 'package:flutter/material.dart';

void main() {
  runApp(const KnittingApp());
}

class KnittingApp extends StatefulWidget {
  const KnittingApp({super.key});

  @override
  State<KnittingApp> createState() => _KnittingAppState();
}

class _KnittingAppState extends State<KnittingApp> {
  String _locale = 'ja';

  final Map<String, Map<String, String>> _localizedValues = {
    'ja': {
      'title': 'セーターチャートジェネレーター',
      'gauge': 'ゲージ',
      'type': 'タイプ',
      'body': '身頃',
      'neck_shoulder': '襟と肩',
      'sleeve': '袖',
      'download': 'ダウンロード',
      'cm': 'センチメートル',
      'inch': 'インチ',
      'length_of_body': '着丈',
      'length_of_shoulder_drop': '肩下がり',
      'length_of_ribbed_hem': '裾のゴム編み',
      'length_of_front_neck_drop': '前襟ぐり下がり',
      'length_of_back_neck_drop': '後襟ぐり下がり',
      'width_of_body': '身幅',
      'width_of_neck': '襟ぐり幅',
      'length_of_sleeve': '袖丈',
      'length_of_ribbed_cuff': '袖口のゴム編み',
      'width_of_sleeve': '袖幅',
      'width_of_cuff': '袖口幅',
      'sts_10cm': '目数 / 10cm',
      'rows_10cm': '段数 / 10cm',
      'sts_4inch': '目数 / 4インチ',
      'rows_4inch': '段数 / 4インチ',
      'crew': 'クルーネック',
      'v_neck': 'Vネック',
      'high': 'ハイネック',
      'cardigan': 'カーディガン',
      'raglan': 'ラグラン',
      'boat': 'ボートネック',
      'turtle': 'タートルネック',
      'open': 'オープンフロント',

    },
    'en': {
      'title': 'SweaterChartGenerator',
      'gauge': 'Gauge',
      'type': 'Type',
      'body': 'Body',
      'neck_shoulder': 'Neck & Shoulder',
      'sleeve': 'Sleeve',
      'download': 'Download as',
      'cm': 'cm',
      'inch': 'inch',
      'length_of_body': 'Body Length',
      'length_of_shoulder_drop': 'Shoulder Drop',
      'length_of_ribbed_hem': 'Ribbed Hem',
      'length_of_front_neck_drop': 'Front Neck Drop',
      'length_of_back_neck_drop': 'Back Neck Drop',
      'width_of_body': 'Body Width',
      'width_of_neck': 'Neck Width',
      'length_of_sleeve': 'Sleeve Length',
      'length_of_ribbed_cuff': 'Ribbed Cuff',
      'width_of_sleeve': 'Sleeve Width',
      'width_of_cuff': 'Cuff Width',
      'sts_10cm': 'Stitches / 10cm',
      'rows_10cm': 'Rows / 10cm',
      'sts_4inch': 'Stitches / 4inch',
      'rows_4inch': 'Rows / 4inch',
      'crew': 'Crew Neck',
      'v_neck': 'V-Neck',
      'high': 'High Neck',
      'cardigan': 'Cardigan',
      'raglan': 'Raglan',
      'boat': 'Boat Neck',
      'turtle': 'Turtle Neck',
      'open': 'Open Front',
    }
  };

  String t(String key) => _localizedValues[_locale]?[key] ?? key;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
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
    {'id': 'PDF', 'label': 'PDF Document', 'icon': Icons.picture_as_pdf, 'color': Colors.red.shade700},
    {'id': 'Excel', 'label': 'Excel Sheet', 'icon': Icons.table_chart, 'color': Colors.green.shade700},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.t('title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),// 外側の余白
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),// 内側の余白
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.currentLocale,
                  icon: const Padding(
                    padding: EdgeInsets.only(left: 4.0), // アイコンと文字の間隔
                    child: Icon(Icons.translate, size: 16, color: Colors.teal),
                  ),
                  alignment: Alignment.center, // テキストを中央寄せ
                  style: const TextStyle(
                    color: Colors.teal, 
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ja', child: Text('JP')),
                    DropdownMenuItem(value: 'en', child: Text('EN')),
                  ],
                  onChanged: widget.onLocaleChange,
                ),
              ),
            ),
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
                border: Border.all(color: isSelected ? Colors.teal : Colors.grey.shade300, width: isSelected ? 3 : 1),
                color: isSelected ? Colors.teal.withValues(alpha: 0.05) : Colors.transparent,
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
                      color: isSelected ? Colors.teal : Colors.black87,
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
              backgroundColor: isSelected ? Colors.teal.withOpacity(0.1) : null,
              side: BorderSide(
                color: isSelected ? Colors.teal : Colors.grey.shade300,
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
                color: isSelected ? Colors.teal : Colors.black87,
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
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.grey, size: 48),
          ),
          const SizedBox(width: 16),
          Expanded(child: SingleChildScrollView(child: Column(children: fields))),
        ],
      ),
    );
  }

  // 広告掲載用カード
  Widget _buildAdCard() {
    return _baseCard(
      title: 'Information', // 広告放送時は「Sponsor」など
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.ads_click, color: Colors.grey, size: 48),
              SizedBox(height: 8),
              Text('Advertisement Area', style: TextStyle(color: Colors.grey)),
            ],
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
                color: (format['color'] as Color).withOpacity(0.1),
                border: Border.all(color: (format['color'] as Color).withOpacity(0.3)),
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
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
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
                  child: Icon(icon, size: 20, color: Colors.teal.shade700),
                ) 
              : null,
          // ここに単位を表示 (例: cm / inch)
          suffixText: suffix?.toLowerCase(), 
          suffixStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
      )
    );
  }
}