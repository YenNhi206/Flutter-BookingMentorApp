import 'package:flutter/foundation.dart';

/// Tab đang chọn trong [MainShell]. Tách thành ViewModel riêng (thay vì
/// state cục bộ) để các màn được push lên trên nó - vd [CartScreen] khi
/// rỗng, hay bất kỳ đâu được push từ 1 tab - có thể chủ động chuyển về
/// tab Home thay vì chỉ pop.
class MainTabViewModel extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void setIndex(int index) {
    if (_index == index) return;
    _index = index;
    notifyListeners();
  }
}
