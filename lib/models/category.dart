/// Model danh mục món ăn (vd: Ice Cream, Cake, Drinks...) - tương ứng
/// bảng `categories`. Dùng làm nguồn dữ liệu cho các filter chip ở Home.
class FoodCategory {
  final String id;
  final String name;
  final String emoji;

  const FoodCategory({
    required this.id,
    required this.name,
    required this.emoji,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
      };

  factory FoodCategory.fromMap(Map<String, Object?> map) => FoodCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        emoji: map['emoji'] as String? ?? '🍬',
      );
}
