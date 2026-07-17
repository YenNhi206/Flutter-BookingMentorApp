import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../viewmodels/auth_vm.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toast.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';
import 'owner_shell.dart';

enum _AuthTab { login, signUp }

/// Màn hình Đăng nhập/Đăng ký gộp chung 1 màn với segmented tab trượt.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _AuthTab _tab = _AuthTab.login;

  /// Tăng mỗi lần đổi tab để báo cho [_AnimatedDonut] biết cần chạy hiệu
  /// ứng xoay/nảy - đơn giản hơn dùng GlobalKey vì widget tự phát hiện thay
  /// đổi qua `didUpdateWidget`.
  int _donutSpinTrigger = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();

    final success = _tab == _AuthTab.login
        ? await auth.login(email: _emailController.text, password: _passwordController.text)
        : await auth.register(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (!mounted) return;
    if (success) {
      final isOwner = auth.currentUser?.isOwner ?? false;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => isOwner ? const OwnerShell() : const MainShell()),
        (route) => false,
      );
    } else {
      AppToast.show(context, message: auth.errorMessage ?? 'Something went wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final isLogin = _tab == _AuthTab.login;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        await context.read<AuthViewModel>().continueAsGuest();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainShell()),
                          (route) => false,
                        );
                      },
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(child: _AnimatedDonut(spinTrigger: _donutSpinTrigger)),
                const SizedBox(height: 12),
                Text(
                  isLogin ? AppConstants.welcomeBack : AppConstants.createAccount,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),
                _SegmentedTabs(
                  isLogin: isLogin,
                  onChanged: (tab) => setState(() {
                    _tab = tab;
                    _donutSpinTrigger++;
                  }),
                ),
                const SizedBox(height: 24),
                if (!isLogin) ...[
                  AppTextField(
                    controller: _nameController,
                    label: 'Full name',
                    hint: 'Your name',
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                  ),
                  const SizedBox(height: 14),
                ],
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: AppConstants.emailHint,
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: AppConstants.passwordHint,
                  validator: _validatePassword,
                ),
                if (!isLogin) ...[
                  const SizedBox(height: 14),
                  PasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirm password',
                    hint: AppConstants.passwordHint,
                    validator: (v) {
                      if (v != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
                if (isLogin) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(AppConstants.forgotPassword),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                PrimaryButton(
                  label: isLogin ? AppConstants.logIn : AppConstants.signUp,
                  isLoading: auth.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented control "Log In / Sign Up" - pill đen trượt sang tab đang chọn.
class _SegmentedTabs extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<_AuthTab> onChanged;

  const _SegmentedTabs({required this.isLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(999)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(_AuthTab.login),
                  child: Center(
                    child: Text(
                      AppConstants.logIn,
                      style: TextStyle(
                        color: isLogin ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(_AuthTab.signUp),
                  child: Center(
                    child: Text(
                      AppConstants.signUp,
                      style: TextStyle(
                        color: !isLogin ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Emoji donut ở đầu màn Auth: tự bồng bềnh (float) + lắc nhẹ liên tục, và
/// khi [spinTrigger] đổi (đổi tab Log In ↔ Sign Up) sẽ chạy thêm 1 vòng xoay
/// kèm nảy (pop) để tạo cảm giác phản hồi vui mắt.
class _AnimatedDonut extends StatefulWidget {
  final int spinTrigger;
  const _AnimatedDonut({required this.spinTrigger});

  @override
  State<_AnimatedDonut> createState() => _AnimatedDonutState();
}

class _AnimatedDonutState extends State<_AnimatedDonut> with TickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void didUpdateWidget(covariant _AnimatedDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinTrigger != oldWidget.spinTrigger) {
      _spinController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _spinController]),
      builder: (context, child) {
        // Bồng bềnh + lắc nhẹ liên tục.
        final floatT = Curves.easeInOut.transform(_floatController.value);
        final dy = -10 * floatT;
        final idleWobble = (floatT - 0.5) * 0.12;

        // Xoay 1 vòng + nảy khi đổi tab.
        final spinAngle = Curves.easeOutBack.transform(_spinController.value) * 2 * math.pi;
        final pop = 1 + 0.25 * math.sin(_spinController.value * math.pi);

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: idleWobble + spinAngle,
            child: Transform.scale(scale: pop, child: child),
          ),
        );
      },
      child: const Text('🍩', style: TextStyle(fontSize: 56)),
    );
  }
}
