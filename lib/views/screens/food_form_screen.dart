import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/colors.dart';
import '../../models/category.dart';
import '../../models/food.dart';
import '../../viewmodels/food_vm.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toast.dart';
import '../widgets/primary_button.dart';

/// Form thêm mới / chỉnh sửa món ăn cho chủ quán. Nếu [food] != null thì đây
/// là chỉnh sửa (prefill toàn bộ field), ngược lại là thêm món mới cho
/// [storeId].
class FoodFormScreen extends StatefulWidget {
  final String storeId;
  final Food? food;

  const FoodFormScreen({super.key, required this.storeId, this.food});

  @override
  State<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends State<FoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.food?.name ?? '');
  late final _descriptionController = TextEditingController(text: widget.food?.description ?? '');
  late final _priceController = TextEditingController(text: widget.food?.price.toString() ?? '');
  late final _emojiController = TextEditingController(text: widget.food?.emoji ?? '🍰');
  late final _kcalController = TextEditingController(text: (widget.food?.kcal ?? 150).toString());
  late final _readyMinutesController = TextEditingController(text: (widget.food?.readyMinutes ?? 5).toString());
  late final _serveTempController = TextEditingController(text: widget.food?.serveTemp ?? '');
  late final _flavourTagsController = TextEditingController(text: widget.food?.flavourTags.join(', ') ?? '');

  String? _categoryId;
  bool _isAvailable = true;
  bool _isSaving = false;

  bool get _isEditing => widget.food != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.food?.categoryId;
    _isAvailable = widget.food?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _emojiController.dispose();
    _kcalController.dispose();
    _readyMinutesController.dispose();
    _serveTempController.dispose();
    _flavourTagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      AppToast.show(context, message: 'Vui lòng chọn danh mục');
      return;
    }

    setState(() => _isSaving = true);
    final foodVm = context.read<FoodViewModel>();

    final flavourTags = _flavourTagsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final food = Food(
      id: widget.food?.id ?? const Uuid().v4(),
      storeId: widget.storeId,
      categoryId: _categoryId!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      emoji: _emojiController.text.trim().isEmpty ? '🍰' : _emojiController.text.trim(),
      rating: widget.food?.rating ?? 4.5,
      isAvailable: _isAvailable,
      kcal: int.tryParse(_kcalController.text.trim()) ?? 150,
      readyMinutes: int.tryParse(_readyMinutesController.text.trim()) ?? 5,
      serveTemp: _serveTempController.text.trim(),
      flavourTags: flavourTags,
    );

    if (_isEditing) {
      await foodVm.updateFood(food);
    } else {
      await foodVm.addFood(food);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<FoodViewModel>().categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEditing ? 'Sửa món' : 'Thêm món mới')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Tên món',
                  hint: 'VD: Bánh Red Velvet',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Tên món là bắt buộc' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Mô tả',
                  hint: 'Mô tả ngắn về món ăn',
                ),
                const SizedBox(height: 14),
                _CategoryDropdown(
                  categories: categories,
                  value: _categoryId,
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _priceController,
                        label: 'Giá (USD)',
                        hint: '5.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final parsed = double.tryParse((v ?? '').trim());
                          if (parsed == null || parsed <= 0) return 'Giá không hợp lệ';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AppTextField(
                        controller: _emojiController,
                        label: 'Emoji',
                        hint: '🍰',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _kcalController,
                        label: 'Kcal',
                        hint: '150',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AppTextField(
                        controller: _readyMinutesController,
                        label: 'Thời gian chuẩn bị (phút)',
                        hint: '5',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _serveTempController,
                  label: 'Nhiệt độ phục vụ',
                  hint: 'VD: Hot, -2°C, Iced',
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _flavourTagsController,
                  label: 'Hương vị (cách nhau bởi dấu phẩy)',
                  hint: 'VD: Sugary, Creamy, Classic',
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  title: const Text('Đang mở bán', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: _isEditing ? 'Lưu thay đổi' : 'Thêm món',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<FoodCategory> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({required this.categories, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Danh mục', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(hintText: 'Chọn danh mục'),
          items: categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.name}')))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
