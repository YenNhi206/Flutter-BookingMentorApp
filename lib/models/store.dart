/// Model cửa hàng - tương ứng bảng `stores`. Toạ độ [lat]/[lng] dùng để
/// hiển thị marker trên bản đồ ở [MapScreen].
class Store {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double rating;
  final String image;

  const Store({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.rating = 4.5,
    this.image = '',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'rating': rating,
        'image': image,
      };

  factory Store.fromMap(Map<String, Object?> map) => Store(
        id: map['id'] as String,
        name: map['name'] as String,
        address: map['address'] as String? ?? '',
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
        image: map['image'] as String? ?? '',
      );
}
