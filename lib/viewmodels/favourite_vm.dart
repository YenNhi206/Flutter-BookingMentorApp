import 'package:flutter/foundation.dart';

import '../repositories/favourite_repository.dart';

/// ViewModel danh sách món yêu thích - giữ 1 [Set] id món để tra cứu
/// O(1) trong lúc render danh sách (tránh query lại DB cho mỗi item).
class FavouriteViewModel extends ChangeNotifier {
  final FavouriteRepository _repository;

  FavouriteViewModel({FavouriteRepository? repository}) : _repository = repository ?? FavouriteRepository();

  Set<String> _favouriteIds = {};

  bool isFavourite(String foodId) => _favouriteIds.contains(foodId);

  List<String> get favouriteIds => _favouriteIds.toList();

  Future<void> load(String userId) async {
    _favouriteIds = await _repository.getFavouriteFoodIds(userId);
    notifyListeners();
  }

  Future<void> toggle(String userId, String foodId) async {
    final nowFavourite = await _repository.toggle(userId, foodId);
    if (nowFavourite) {
      _favouriteIds.add(foodId);
    } else {
      _favouriteIds.remove(foodId);
    }
    notifyListeners();
  }
}
