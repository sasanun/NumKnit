class AdProduct {
  final String url;
  final String mp;
  final String category;
  final String name;
  final String image;

  AdProduct({
    required this.url,
    required this.mp,
    required this.category,
    required this.name,
    required this.image,
  });

  factory AdProduct.fromMap(Map<String, dynamic> map) {
    return AdProduct(
      url: map['url'] as String,
      mp: map['mp'] as String,
      category: map['category'] as String,
      name: map['name'] as String,
      image: map['image'] as String,
    );
  }
}