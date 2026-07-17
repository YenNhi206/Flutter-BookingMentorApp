import 'package:intl/intl.dart';

/// Các hàm định dạng dùng chung: tiền tệ (dạng $X.XX theo UI mẫu) và ngày giờ.
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currency = NumberFormat.currency(locale: 'en_US', symbol: r'$');

  /// Định dạng giá tiền theo kiểu "$5.00" như trong thiết kế mẫu.
  static String currency(double amount) => _currency.format(amount);

  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _time = DateFormat('HH:mm');

  static String shortDate(DateTime date) => _shortDate.format(date);

  static String dateTime(DateTime date) => _dateTime.format(date);

  static String time(DateTime date) => _time.format(date);

  /// Định dạng mã đơn hàng ngắn gọn để hiển thị (8 ký tự đầu, viết hoa).
  static String orderCode(String orderId) =>
      '#${orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}';
}
