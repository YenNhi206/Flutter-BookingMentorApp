import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../viewmodels/auth_vm.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';
import 'owner_shell.dart';

/// Màn hình mở app: bánh quy lăn chậm từ trái vào giữa, tên "Scoops" +
/// tagline xuất hiện rồi biến mất, cuối cùng bánh quy từ từ rơi xuống đáy
/// màn hình. Khi animation xong, tự kiểm tra phiên đăng nhập và điều hướng.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _text = AppConstants.appName;
  static const _letterStep = 0.028;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800));
    _controller.addStatusListener(_onStatusChanged);
    _controller.forward();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _navigateNext();
    }
  }

  Future<void> _navigateNext() async {
    final auth = context.read<AuthViewModel>();
    await auth.restoreSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => _homeFor(auth)),
    );
  }

  /// Chủ quán vào thẳng màn quản lý quán; khách/guest vào khung điều hướng
  /// mua hàng bình thường; chưa đăng nhập thì vào onboarding.
  Widget _homeFor(AuthViewModel auth) {
    if (auth.status == AuthStatus.authenticated) {
      return auth.currentUser!.isOwner ? const OwnerShell() : const MainShell();
    }
    if (auth.status == AuthStatus.guest) return const MainShell();
    return const OnboardingScreen();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final screenWidth = MediaQuery.sizeOf(context).width;
            final screenHeight = MediaQuery.sizeOf(context).height;

            // 1) Bánh lăn ngang đều mượt từ mép trái vào giữa (easeOut),
            // đồng thời nảy lên-xuống nhẹ như quả bóng, tắt dần rồi chạm đất
            // đúng lúc lăn xong (bounceOut cho trục dọc).
            final rollT = (t / 0.32).clamp(0.0, 1.0);
            final rollEased = Curves.easeOut.transform(rollT);
            final rollDx = (1 - rollEased) * -(screenWidth / 2 + 100);
            final rollRotation = rollEased * 4 * math.pi;
            final rollHop = Curves.bounceOut.transform(rollT);
            final rollDy = (1 - rollHop) * -22;

            // 2) Chữ "Scoops" + tagline xuất hiện (36-66%), giữ 1 nhịp rồi
            // biến mất (70-80%).
            final groupFadeOut = 1 - ((t - 0.70) / 0.10).clamp(0.0, 1.0);
            final taglineAppear = ((t - 0.50) / 0.12).clamp(0.0, 1.0);
            final taglineOpacity = taglineAppear * groupFadeOut;

            // 3) Bánh từ từ rơi xuống đáy màn hình sau khi chữ đã biến mất
            // (80-100%) - kéo dài hơn để rơi chậm, không bị rớt cái rụp.
            final fallT = ((t - 0.80) / 0.20).clamp(0.0, 1.0);
            final fallEased = Curves.easeIn.transform(fallT);
            final fallDy = fallEased * (screenHeight * 0.55);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(rollDx, rollDy + fallDy),
                  child: Transform.rotate(
                    angle: rollRotation,
                    child: const Text('🍪', style: TextStyle(fontSize: 144)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_text.length, (i) {
                    final start = 0.34 + i * _letterStep;
                    final localT = ((t - start) / 0.14).clamp(0.0, 1.0);
                    final eased = Curves.easeOutBack.transform(localT);
                    return Opacity(
                      opacity: localT * groupFadeOut,
                      child: Transform.translate(
                        offset: Offset(0, (1 - eased) * 18),
                        child: Text(
                          _text[i],
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: taglineOpacity,
                  child: Text(
                    AppConstants.appTagline,
                    style: GoogleFonts.pacifico(fontSize: 22, color: AppColors.primary),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
