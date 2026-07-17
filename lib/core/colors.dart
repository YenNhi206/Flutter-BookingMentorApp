import 'package:flutter/material.dart';

/// Bảng màu thương hiệu của Scoops: nền trắng, điểm nhấn đen tuyền,
/// và các tông pastel dùng làm nền ảnh món ăn.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFFFDFB);
  static const Color backgroundSecondary = Color(0xFFFAF7F3);

  /// Màu điểm nhấn chính: dùng cho nút chính, bottom nav, chip đang chọn.
  /// Đen ấm (thay vì đen tuyền) để mềm mại, sang trọng hơn.
  static const Color primary = Color(0xFF1E1B18);
  static const Color onPrimary = Color(0xFFFFFDFB);

  static const Color textPrimary = Color(0xFF221F1C);
  static const Color textSecondary = Color(0xFF9B948B);

  /// Nền card món ăn (khi không dùng tông pastel riêng).
  static const Color surfaceCard = Color(0xFFF6F1EB);

  static const Color divider = Color(0xFFEFE8E0);

  /// Màu đổ bóng mềm dùng chung - ấm hơn đen tuyền để tránh cảm giác cứng.
  static const Color shadow = Color(0xFF4A3F33);

  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF34C759);

  /// Hồng đỏ - CHỈ dùng cho timeline trạng thái đơn hàng và status pill.
  /// Nguyên tắc màu: đen = hành động (nút/nav/chip active), hồng đỏ = trạng
  /// thái đơn hàng - không trộn 2 vai trò này với nhau.
  static const Color statusAccent = Color(0xFFFF4D6D);

  /// Các tông pastel dùng làm nền ảnh món ăn, chọn xoay vòng theo danh mục
  /// để mỗi món trông khác biệt mà vẫn hài hoà.
  static const List<Color> pastelTints = [
    Color(0xFFFFE8EC),
    Color(0xFFE8F4FF),
    Color(0xFFFFF4E0),
    Color(0xFFEAFBF0),
    Color(0xFFF3E8FF),
  ];

  /// Trả về 1 tông pastel cố định dựa theo [seed] (vd index hoặc hashCode)
  /// để cùng 1 món luôn nhận cùng 1 màu nền qua các lần rebuild.
  static Color pastelForSeed(int seed) => pastelTints[seed.abs() % pastelTints.length];
}
