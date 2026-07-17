import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/formatters.dart';
import '../../models/food.dart';
import '../../viewmodels/auth_vm.dart';
import '../../viewmodels/cart_vm.dart';
import '../../viewmodels/food_vm.dart';
import '../widgets/app_toast.dart';
import '../widgets/primary_button.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/stat_tile.dart';
import 'cart_screen.dart';

/// Chi tiết món ăn: ảnh lớn nền trắng (Hero từ Home), stepper số lượng,
/// tổng giá realtime, 3 ô thông số (kcal/thời gian chuẩn bị/nhiệt độ phục
/// vụ), chip hương vị, nút "Add to Cart".
class FoodDetailScreen extends StatefulWidget {
  final String foodId;

  /// Tag Hero khớp với card đã bấm để mở màn này - nếu màn được mở từ nơi
  /// không có Hero nguồn (vd sâu trong luồng khác), dùng tag mặc định riêng
  /// của route này để tránh trùng với bất kỳ Hero nào khác đang hiển thị.
  final String? heroTag;

  const FoodDetailScreen({super.key, required this.foodId, this.heroTag});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  int _quantity = 1;
  bool _isFavourite = false;

  Future<void> _addToCart(Food food) async {
    final auth = context.read<AuthViewModel>();
    final cart = context.read<CartViewModel>();
    cart.userId = auth.currentUser?.id;

    await cart.addItem(food, size: FoodSize.small, quantity: _quantity);
    if (!mounted) return;
    AppToast.show(
      context,
      message: '${food.name} added to cart 🎉',
      actionLabel: 'View Cart',
      onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodVm = context.watch<FoodViewModel>();
    final food = foodVm.getById(widget.foodId);
    final cartCount = context.watch<CartViewModel>().totalQuantity;

    if (food == null) {
      return const Scaffold(body: Center(child: Text('Food not found')));
    }

    final category = foodVm.getCategoryById(food.categoryId);
    final totalPrice = food.price * _quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Text('Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                  _CircleIconButton(
                    icon: Icons.shopping_bag_outlined,
                    badgeCount: cartCount,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: widget.heroTag ?? 'food_detail_${food.id}',
                      child: SizedBox(
                        height: 220,
                        width: 220,
                        child: RepaintBoundary(
                          child: food.image.isEmpty
                              ? FittedBox(
                                  fit: BoxFit.contain,
                                  child: Text(food.emoji, style: const TextStyle(fontSize: 200)),
                                )
                              : Image.asset(food.image, fit: BoxFit.contain, height: 220),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _CircleIconButton(
                      icon: _isFavourite ? Icons.favorite : Icons.favorite_border,
                      iconColor: _isFavourite ? Colors.redAccent : AppColors.textPrimary,
                      onTap: () => setState(() => _isFavourite = !_isFavourite),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  QuantityStepper(
                    outlined: true,
                    quantity: _quantity,
                    onIncrement: () => setState(() => _quantity++),
                    onDecrement: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Price', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.currency(totalPrice),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(food.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 20)),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(food.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  category?.name ?? 'Sweets',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ),
              if (!food.isAvailable) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0x1FE53935), borderRadius: BorderRadius.circular(999)),
                  child: const Text(
                    'Currently unavailable',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: StatRow(
                  tiles: [
                    StatTile(icon: Icons.local_fire_department_outlined, value: '${food.kcal}', label: 'kcal'),
                    StatTile(icon: Icons.access_time, value: '${food.readyMinutes} min', label: 'Ready in'),
                    StatTile(icon: Icons.ac_unit, value: food.serveTemp, label: 'Served'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Flavour', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: food.flavourTags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration:
                              BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(999)),
                          child: Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: food.isAvailable ? 'Add to Cart · ${AppFormatters.currency(totalPrice)}' : 'Currently unavailable',
                trailingIcon: null,
                onPressed: food.isAvailable ? () => _addToCart(food) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút icon tròn nền xám `#F5F5F7` 44px dùng cho back/cart/favourite trên
/// Detail Screen - có thể kèm badge số lượng (dùng cho icon giỏ hàng).
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final int badgeCount;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: AppColors.surfaceCard, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: iconColor ?? AppColors.textPrimary),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(color: AppColors.statusAccent, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
