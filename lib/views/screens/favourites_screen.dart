import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../models/food.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/cart_vm.dart';
import '../../viewmodels/favourite_vm.dart';
import '../../viewmodels/food_vm.dart';
import '../../viewmodels/main_tab_vm.dart';
import '../widgets/app_toast.dart';
import '../widgets/empty_state.dart';
import '../widgets/food_card.dart';
import 'food_detail_screen.dart';

/// Tab "Yêu thích" - liệt kê các món đã được đánh dấu trái tim ở Home/Detail.
class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthViewModel>().currentUser?.id;
      if (userId != null) context.read<FavouriteViewModel>().load(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthViewModel>().currentUser?.id;
    if (userId == null) {
      return const Scaffold(
        body: EmptyState(
          emoji: '🤍',
          title: 'Log in to see favourites',
          subtitle: 'Sign in to save and view your favourite sweets.',
        ),
      );
    }

    final foodVm = context.watch<FoodViewModel>();
    final favouriteVm = context.watch<FavouriteViewModel>();
    final favourites =
        favouriteVm.favouriteIds.map(foodVm.getById).whereType<Food>().where((f) => f.isAvailable).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Favourites')),
      body: favourites.isEmpty
          ? EmptyState(
              emoji: '🤍',
              title: 'No favourites yet',
              subtitle: 'Tap the heart on any sweet to save it here.',
              actionLabel: 'Browse sweets',
              onAction: () => context.read<MainTabViewModel>().setIndex(0),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: favourites.length,
              itemBuilder: (context, index) {
                final food = favourites[index];
                final heroTag = 'favourite_${food.id}';
                return FoodCard(
                  food: food,
                  isFavourite: true,
                  pastelColor: AppColors.pastelForSeed(index),
                  heroTag: heroTag,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FoodDetailScreen(foodId: food.id, heroTag: heroTag)),
                  ),
                  onToggleFavourite: () => context.read<FavouriteViewModel>().toggle(userId, food.id),
                  onAdd: () {
                    context.read<CartViewModel>().addItem(food);
                    AppToast.show(context, message: '${food.name} added to cart 🛍️', duration: const Duration(milliseconds: 900));
                  },
                );
              },
            ),
    );
  }
}
