/// Model món ăn - tương ứng bảng `foods`.
///
/// [image] là đường dẫn asset (vd `assets/foods/scoops.png`) - hiện tại dự
/// án chưa có ảnh 3D thật nên để rỗng, UI sẽ tự fallback sang hiển thị
/// [emoji] cỡ lớn trên nền pastel. Khi có ảnh thật, chỉ cần seed lại giá trị
/// [image] là widget sẽ tự chuyển sang dùng `Image.asset`.
class Food {
  final String id;
  final String storeId;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final String image;
  final String emoji;
  final double rating;
  final bool isAvailable;

  /// Lượng calo - hiển thị ở ô thông số (stat tile) trên Detail Screen.
  final int kcal;

  /// Số phút chuẩn bị món - hiển thị ở ô thông số "Ready in".
  final int readyMinutes;

  /// Nhiệt độ phục vụ dạng text ngắn (vd "-2°C", "Hot") - ô thông số "Served".
  final String serveTemp;

  /// Nhãn hương vị (vd Sugary, Playful, Sweet) - hiển thị dạng chip ở section
  /// "Flavour". Lưu dạng list trong bộ nhớ, nhưng SQLite chỉ có cột TEXT nên
  /// [toMap]/[fromMap] tự nối/tách bằng dấu phẩy (CSV).
  final List<String> flavourTags;

  const Food({
    required this.id,
    required this.storeId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    this.image = '',
    this.emoji = '🍨',
    this.rating = 4.5,
    this.isAvailable = true,
    this.kcal = 150,
    this.readyMinutes = 5,
    this.serveTemp = '',
    this.flavourTags = const [],
  });

  Food copyWith({
    String? categoryId,
    String? name,
    String? description,
    double? price,
    String? image,
    String? emoji,
    bool? isAvailable,
    int? kcal,
    int? readyMinutes,
    String? serveTemp,
    List<String>? flavourTags,
  }) {
    return Food(
      id: id,
      storeId: storeId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      emoji: emoji ?? this.emoji,
      rating: rating,
      isAvailable: isAvailable ?? this.isAvailable,
      kcal: kcal ?? this.kcal,
      readyMinutes: readyMinutes ?? this.readyMinutes,
      serveTemp: serveTemp ?? this.serveTemp,
      flavourTags: flavourTags ?? this.flavourTags,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'store_id': storeId,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'image': image,
        'emoji': emoji,
        'rating': rating,
        'is_available': isAvailable ? 1 : 0,
        'kcal': kcal,
        'ready_minutes': readyMinutes,
        'serve_temp': serveTemp,
        'flavour_tags': flavourTags.join(','),
      };

  factory Food.fromMap(Map<String, Object?> map) => Food(
        id: map['id'] as String,
        storeId: map['store_id'] as String? ?? '',
        categoryId: map['category_id'] as String? ?? '',
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        price: (map['price'] as num).toDouble(),
        image: map['image'] as String? ?? '',
        emoji: map['emoji'] as String? ?? '🍨',
        rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
        isAvailable: ((map['is_available'] as int?) ?? 1) == 1,
        kcal: (map['kcal'] as int?) ?? 150,
        readyMinutes: (map['ready_minutes'] as int?) ?? 5,
        serveTemp: map['serve_temp'] as String? ?? '',
        flavourTags: ((map['flavour_tags'] as String?) ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

/// Kích cỡ món (S/M/L) - mỗi size có phụ phí riêng, dùng ở màn Food Detail.
enum FoodSize { small, medium, large }

extension FoodSizeX on FoodSize {
  String get label => switch (this) {
        FoodSize.small => 'S',
        FoodSize.medium => 'M',
        FoodSize.large => 'L',
      };

  /// Phụ phí cộng thêm vào giá gốc của món theo size.
  double get surcharge => switch (this) {
        FoodSize.small => 0,
        FoodSize.medium => 0.5,
        FoodSize.large => 1.0,
      };
}
