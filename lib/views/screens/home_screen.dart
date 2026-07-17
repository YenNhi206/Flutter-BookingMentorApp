import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../models/food.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/cart_vm.dart';
import '../../viewmodels/chat_vm.dart';
import '../../viewmodels/favourite_vm.dart';
import '../../viewmodels/food_vm.dart';
import '../../viewmodels/notification_vm.dart';
import '../widgets/app_toast.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/filter_chip.dart';
import '../widgets/food_card.dart';
import '../widgets/shimmer_box.dart';
import 'food_detail_screen.dart';
import 'notifications_screen.dart';

/// Tab "Discover food" - màn hình chính của app: tìm kiếm, lọc theo danh
/// mục, lưới 2 cột món ăn và section "We Recommend".
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final food = context.read<FoodViewModel>();
    await food.loadAll();
    if (!mounted) return;

    final auth = context.read<AuthViewModel>();
    final userId = auth.currentUser?.id;
    if (userId != null) {
      await context.read<FavouriteViewModel>().load(userId);
      if (!mounted) return;
      await context.read<NotificationViewModel>().load(userId);
      if (!mounted) return;
      await context.read<ChatViewModel>().loadUnreadCount(userId);
      if (!mounted) return;
      context.read<CartViewModel>().userId = userId;
      await context.read<CartViewModel>().load(userId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foodVm = context.watch<FoodViewModel>();
    final favouriteVm = context.watch<FavouriteViewModel>();
    final cartVm = context.watch<CartViewModel>();
    final unread = context.watch<NotificationViewModel>().unreadCount;

    final filtered = foodVm.filteredFoods;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<FoodViewModel>().loadAll(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Ice cream Lover?\nOrder & Eat.',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceCard,
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_none_rounded),
                                if (unread > 0)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          context.read<FoodViewModel>().setSearchQuery(v),
                      decoration: const InputDecoration(
                        hintText: AppConstants.searchHint,
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      AppConstants.discoverFood,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      children: [
                        AppFilterChip(
                          label: AppConstants.filterAll,
                          selected: foodVm.selectedCategoryId == null,
                          onTap: () => context
                              .read<FoodViewModel>()
                              .selectCategory(null),
                        ),
                        const SizedBox(width: 8),
                        ...foodVm.categories.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AppFilterChip(
                              label: c.name,
                              selected: foodVm.selectedCategoryId == c.id,
                              onTap: () => context
                                  .read<FoodViewModel>()
                                  .selectCategory(c.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (foodVm.isLoading)
                const SliverToBoxAdapter(child: FoodGridShimmer())
              else if (filtered.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Text(
                        'No sweets found 😢',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => FadeSlideIn(
                        delay: Duration(
                          milliseconds: 260 + index.clamp(0, 8) * 40,
                        ),
                        child: _buildFoodCard(
                          context,
                          filtered[index],
                          index,
                          favouriteVm,
                          cartVm,
                          'grid_${filtered[index].id}',
                        ),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 500),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      AppConstants.weRecommend,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 210,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: foodVm.recommended.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final food = foodVm.recommended[index];
                      return SizedBox(
                        width: 140,
                        child: FadeSlideIn(
                          delay: Duration(
                            milliseconds: 540 + index.clamp(0, 8) * 40,
                          ),
                          child: _buildFoodCard(
                            context,
                            food,
                            index,
                            favouriteVm,
                            cartVm,
                            'recommend_${food.id}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodCard(
    BuildContext context,
    Food food,
    int index,
    FavouriteViewModel favouriteVm,
    CartViewModel cartVm,
    String heroTag,
  ) {
    final auth = context.read<AuthViewModel>();
    return FoodCard(
      food: food,
      isFavourite: favouriteVm.isFavourite(food.id),
      pastelColor: AppColors.pastelForSeed(index),
      heroTag: heroTag,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FoodDetailScreen(foodId: food.id, heroTag: heroTag),
        ),
      ),
      onToggleFavourite: () {
        final userId = auth.currentUser?.id;
        if (userId == null) {
          _showLoginRequired(context);
          return;
        }
        context.read<FavouriteViewModel>().toggle(userId, food.id);
      },
      onAdd: () {
        cartVm.addItem(food);
        AppToast.show(
          context,
          message: '${food.name} added to cart 🛍️',
          duration: const Duration(milliseconds: 900),
        );
      },
    );
  }

  void _showLoginRequired(BuildContext context) {
    AppToast.show(context, message: 'Please log in to save favourites.');
  }
}
