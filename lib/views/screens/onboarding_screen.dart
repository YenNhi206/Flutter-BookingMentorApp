import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../viewmodels/auth_vm.dart';
import 'auth_screen.dart';
import 'main_shell.dart';

const _onboardingEmojis = ['🍦', '🍰', '🍪', '🧋', '🧁', '🍩', '🥐', '🍓', '🍫'];

/// Màn hình giới thiệu đầu tiên: 3 hàng icon món ăn cỡ lớn, tự trôi ngang
/// qua lại chầm chậm (không cần vuốt), hàng giữa lệch pha ngược hướng cho
/// sinh động, ở nửa trên; headline + 2 nút hành động ở nửa dưới.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 10.0;
                    final tileSize = (constraints.maxWidth - gap * 2) / 3.3;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MarqueeRow(
                          emojis: _onboardingEmojis.sublist(0, 3),
                          seedOffset: 0,
                          tileSize: tileSize,
                        ),
                        _MarqueeRow(
                          emojis: _onboardingEmojis.sublist(3, 6),
                          seedOffset: 3,
                          tileSize: tileSize,
                          reverse: true,
                        ),
                        _MarqueeRow(
                          emojis: _onboardingEmojis.sublist(6, 9),
                          seedOffset: 6,
                          tileSize: tileSize,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppConstants.onboardingHeadline,
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      AppConstants.onboardingSubtitle,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(AppConstants.joinMember),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _continueAsGuest(context),
                      child: const Text(
                        AppConstants.continueAsGuest,
                        style: TextStyle(decoration: TextDecoration.underline, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continueAsGuest(BuildContext context) async {
    await context.read<AuthViewModel>().continueAsGuest();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }
}

/// Một hàng icon món ăn lặp lại, tự trượt ngang qua lại chầm chậm (không
/// cần người dùng thao tác) bằng cách đẩy [ScrollController] theo giá trị
/// của [AnimationController] chạy `repeat(reverse: true)`. [reverse] đảo
/// pha ban đầu để hàng này trôi ngược hướng các hàng còn lại.
class _MarqueeRow extends StatefulWidget {
  final List<String> emojis;
  final int seedOffset;
  final double tileSize;
  final bool reverse;

  const _MarqueeRow({
    required this.emojis,
    required this.seedOffset,
    required this.tileSize,
    this.reverse = false,
  });

  @override
  State<_MarqueeRow> createState() => _MarqueeRowState();
}

class _MarqueeRowState extends State<_MarqueeRow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..addListener(_onTick)
      ..repeat(reverse: true);
  }

  void _onTick() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final t = Curves.easeInOut.transform(_controller.value);
    _scrollController.jumpTo(maxExtent * (widget.reverse ? 1 - t : t));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = List.generate(widget.emojis.length * 3, (i) => widget.emojis[i % widget.emojis.length]);
    return SizedBox(
      height: widget.tileSize,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < tiles.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Container(
                  width: widget.tileSize,
                  height: widget.tileSize,
                  decoration: BoxDecoration(
                    color: AppColors.pastelForSeed(widget.seedOffset + i),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(tiles[i], style: TextStyle(fontSize: widget.tileSize * 0.5)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
